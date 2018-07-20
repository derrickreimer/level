defmodule Level.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query
  import Level.Gettext

  alias Ecto.Multi
  alias Level.Repo
  alias Level.Users.Reservation
  alias Level.Users.User

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
  end

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
    |> Repo.update_all(set: [first_name: user.first_name, last_name: user.last_name])
    |> handle_space_users_update()
  end

  defp handle_space_users_update({count, _}), do: {:ok, count}
  defp handle_user_update({:ok, %{user: user}}), do: {:ok, user}

  defp handle_user_update({:error, :user, %Ecto.Changeset{} = changeset, _}),
    do: {:error, changeset}

  defp handle_user_update(_), do: {:error, dgettext("errors", "An unexpected error occurred")}

  @doc """
  Count the number of reservations.
  """
  @spec reservation_count() :: Integer.t()
  def reservation_count do
    Repo.one(from(r in Reservation, select: count(r.id)))
  end
end
