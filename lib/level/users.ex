defmodule Level.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query
  import Level.Gettext

  alias Ecto.Multi
  alias Level.Analytics
  alias Level.AssetStore
  alias Level.Email
  alias Level.Mailer
  alias Level.Repo
  alias Level.Schemas.PasswordReset
  alias Level.Schemas.Reservation
  alias Level.Schemas.User
  alias Level.Spaces
  alias Level.WebPush

  @doc """
  Fetches a user by id.
  """
  @spec get_user_by_id(String.t()) :: {:ok, User.t()} | {:error, String.t()}
  def get_user_by_id(id) do
    case Repo.get(User, id) do
      %User{} = user ->
        {:ok, user}

      _ ->
        {:error, dgettext("errors", "User not found")}
    end
  end

  @doc """
  Fetches a user by email.
  """
  @spec get_user_by_email(String.t()) :: {:ok, User.t()} | {:error, String.t()}
  def get_user_by_email(email) do
    case Repo.get_by(User, %{email: email}) do
      %User{} = user ->
        {:ok, user}

      _ ->
        {:error, dgettext("errors", "User not found")}
    end
  end

  @doc """
  Fetches users by handles.
  """
  @spec get_users_by_handle([String.t()]) :: [User.t()]
  def get_users_by_handle(handles) do
    query = from u in User, where: u.handle in ^handles
    Repo.all(query)
  end

  @doc """
  Generates a changeset for creating a user.
  """
  @spec create_user_changeset(User.t(), map()) :: Ecto.Changeset.t()
  def create_user_changeset(user, params \\ %{}) do
    User.create_changeset(user, params)
  end

  @doc """
  Creates a new user.
  """
  @spec create_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(params) do
    %User{}
    |> create_user_changeset(params)
    |> Repo.insert()
    |> after_create_user()
  end

  defp after_create_user({:ok, user}) do
    send_identity_to_analytics(user)
    {:ok, user}
  end

  defp after_create_user(err), do: err

  @doc """
  Creates a new user with a demo space.
  """
  @spec create_user_with_demo(map()) ::
          {:ok, %{user: User.t(), space: Space.t()}} | {:error, Ecto.Changeset.t()}
  def create_user_with_demo(params) do
    %User{}
    |> create_user_changeset(params)
    |> Repo.insert()
    |> create_demo_space_after_user()
  end

  defp create_demo_space_after_user({:ok, user}) do
    {:ok, %{space: demo_space}} = Spaces.create_demo_space(user)
    send_identity_to_analytics(user)
    {:ok, %{user: user, space: demo_space}}
  end

  defp create_demo_space_after_user(err), do: err

  @doc """
  Creates a reservation.
  """
  @spec create_reservation(map()) :: {:ok, Reservation.t()} | {:error, Ecto.Changeset.t()}
  def create_reservation(params) do
    %Reservation{}
    |> Reservation.create_changeset(params)
    |> Repo.insert()
  end

  @doc """
  Looks up a reservation.
  """
  @spec get_reservation(String.t()) :: {:ok, Reservation.t()} | {:error, String.t()}
  def get_reservation(handle) do
    case Repo.get_by(Reservation, handle: handle) do
      %Reservation{} = reservation ->
        {:ok, reservation}

      _ ->
        {:error, dgettext("errors", "Handle is not reserved")}
    end
  end

  @doc """
  Updates a user.
  """
  @spec update_user(User.t(), map()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t() | String.t()}
  def update_user(user, params) do
    Multi.new()
    |> Multi.update(:user, User.update_changeset(user, params))
    |> Multi.run(:update_space_users, &update_space_users/1)
    |> Repo.transaction()
    |> handle_user_update()
  end

  defp update_space_users(%{user: user}) do
    user
    |> Ecto.assoc(:space_users)
    |> Repo.all()
    |> Enum.each(copy_user_params(user))

    {:ok, true}
  end

  defp copy_user_params(user) do
    fn space_user ->
      Spaces.update_space_user(space_user, %{
        first_name: user.first_name,
        last_name: user.last_name,
        handle: user.handle,
        avatar: user.avatar
      })
    end
  end

  defp handle_user_update({:ok, %{user: user}}) do
    send_identity_to_analytics(user)
    {:ok, user}
  end

  defp handle_user_update({:error, :user, %Ecto.Changeset{} = changeset, _}) do
    {:error, changeset}
  end

  defp handle_user_update(_) do
    {:error, dgettext("errors", "An unexpected error occurred")}
  end

  @doc """
  Updates the user's avatar.
  """
  @spec update_avatar(User.t(), String.t()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t() | String.t()}
  def update_avatar(user, raw_data) do
    raw_data
    |> AssetStore.persist_avatar()
    |> set_user_avatar(user)
  end

  defp set_user_avatar({:ok, filename}, user) do
    update_user(user, %{avatar: filename})
  end

  defp set_user_avatar(:error, _user) do
    {:error, dgettext("errors", "An error occurred updating your avatar")}
  end

  @doc """
  Count the number of reservations.
  """
  @spec reservation_count() :: integer()
  def reservation_count do
    Repo.one(from(r in Reservation, select: count(r.id)))
  end

  @doc """
  Inserts a push subscription (gracefully de-duplicated).
  """
  @spec create_push_subscription(User.t(), String.t()) ::
          {:ok, WebPush.Subscription.t()} | {:error, atom()}
  def create_push_subscription(%User{id: user_id}, data) do
    case WebPush.subscribe(user_id, data) do
      {:ok, %{subscription: subscription}} -> {:ok, subscription}
      err -> err
    end
  end

  @doc """
  Fetches all push subscriptions for the given user ids.
  """
  @spec get_push_subscriptions([String.t()]) :: %{
          optional(String.t()) => [WebPush.Subscription.t()]
        }
  def get_push_subscriptions(user_ids) do
    WebPush.get_subscriptions(user_ids)
  end

  @doc """
  Initiates password reset.
  """
  @spec initiate_password_reset(User.t()) :: {:ok, PasswordReset.t()} | no_return()
  def initiate_password_reset(%User{} = user) do
    one_day_from_now =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(60 * 60 * 24)

    %PasswordReset{}
    |> Ecto.Changeset.change(%{user_id: user.id, expires_at: one_day_from_now})
    |> Repo.insert!()
    |> after_insert_password_reset(user)
  end

  defp after_insert_password_reset(reset, user) do
    user
    |> Email.password_reset(reset)
    |> Mailer.deliver_now()

    {:ok, reset}
  end

  @doc """
  Fetches a password reset record.
  """
  @spec get_password_reset(String.t()) :: {:ok, PasswordReset.t()} | {:error, String.t()}
  def get_password_reset(id) do
    now = NaiveDateTime.utc_now()

    query =
      from pr in PasswordReset,
        where: pr.id == ^id and pr.expires_at > ^now

    case Repo.one(query) do
      nil -> {:error, dgettext("errors", "Password reset not found")}
      reset -> {:ok, Repo.preload(reset, :user)}
    end
  end

  @doc """
  Builds a reset password changeset.
  """
  @spec reset_password_changeset(User.t(), map()) :: Ecto.Changeset.t()
  def reset_password_changeset(%User{} = user, params \\ %{}) do
    User.reset_password_changeset(user, params)
  end

  @doc """
  Resets the user's password.
  """
  @spec reset_password(PasswordReset.t(), String.t()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def reset_password(%PasswordReset{} = reset, new_password) do
    reset.user
    |> reset_password_changeset(%{password: new_password})
    |> Repo.update()
  end

  @doc """
  Send user data to external providers asynchronously.
  """
  @spec send_identity_to_analytics(User.t()) :: any()
  def send_identity_to_analytics(user) do
    Analytics.identify(user.email, %{
      user_id: user.id,
      custom_fields: %{
        first_name: user.first_name,
        last_name: user.last_name
      }
    })
  end

  @doc """
  Tracks an event with external providers.
  """
  @spec track_analytics_event(User.t(), String.t(), map()) :: any()
  def track_analytics_event(user, action, props \\ %{}) do
    Analytics.track(user.email, action, props)
  end
end
