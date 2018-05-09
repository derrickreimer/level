defmodule Level.Spaces do
  @moduledoc """
  The Spaces context.
  """

  import Ecto.Query
  import Level.Gettext

  alias Ecto.Multi
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceSetupTransition
  alias Level.Spaces.SpaceUser
  alias Level.Repo
  alias Level.Users.User

  @typedoc "The result of creating a space"
  @type create_space_result ::
          {:ok, %{space: Space.t(), space_user: SpaceUser.t()}}
          | {:error, :space | :space_user, any(), %{optional(:space | :space_user) => any()}}

  @typedoc "The result of getting a space"
  @type get_space_result ::
          {:ok, %{space: Space.t(), space_user: SpaceUser.t()}} | {:error, String.t()}

  @typedoc "Possible space setup states"
  @type space_setup_states :: :create_groups | :invite_users | :complete

  @doc """
  Fetches a space by id.
  """
  @spec get_space(User.t(), String.t()) :: get_space_result()
  def get_space(user, id) do
    with %Space{} = space <- Repo.get(Space, id),
         %SpaceUser{} = space_user <- Repo.get_by(SpaceUser, user_id: user.id, space_id: space.id) do
      {:ok, %{space: space, space_user: space_user}}
    else
      _ ->
        {:error, dgettext("errors", "Space not found")}
    end
  end

  @doc """
  Fetches a space by slug.
  """
  @spec get_space_by_slug(User.t(), String.t()) :: get_space_result()
  def get_space_by_slug(user, slug) do
    with %Space{} = space <- Repo.get_by(Space, %{slug: slug}),
         %SpaceUser{} = space_user <- Repo.get_by(SpaceUser, user_id: user.id, space_id: space.id) do
      {:ok, %{space: space, space_user: space_user}}
    else
      _ ->
        {:error, dgettext("errors", "Space not found")}
    end
  end

  @doc """
  Creates a new space.
  """
  @spec create_space(User.t(), map()) :: create_space_result()
  def create_space(user, params) do
    Multi.new()
    |> Multi.insert(:space, Space.create_changeset(%Space{}, params))
    |> Multi.run(:space_user, fn %{space: space} -> create_owner(user, space) end)
    |> Repo.transaction()
  end

  @doc """
  Establishes a user as an owner of space.
  """
  @spec create_owner(User.t(), Space.t()) :: {:ok, SpaceUser.t()} | {:error, Ecto.Changeset.t()}
  def create_owner(user, space) do
    %SpaceUser{}
    |> SpaceUser.create_changeset(%{user_id: user.id, space_id: space.id, role: "OWNER"})
    |> Repo.insert()
  end

  @doc """
  Establishes a user as a member of a space.
  """
  @spec create_member(User.t(), Space.t()) :: {:ok, SpaceUser.t()} | {:error, Ecto.Changeset.t()}
  def create_member(user, space) do
    %SpaceUser{}
    |> SpaceUser.create_changeset(%{user_id: user.id, space_id: space.id, role: "MEMBER"})
    |> Repo.insert()
  end

  @doc """
  Determines the setup state for a space.
  """
  @spec get_setup_state(Space.t()) :: {:ok, space_setup_states()}
  def get_setup_state(space) do
    completed_states =
      Repo.all(from t in SpaceSetupTransition, where: t.space_id == ^space.id, select: t.state)

    next_state =
      cond do
        Enum.member?(completed_states, "INVITE_USERS") -> :complete
        Enum.member?(completed_states, "CREATE_GROUPS") -> :invite_users
        true -> :create_groups
      end

    {:ok, next_state}
  end

  @doc """
  Marks a setup state as complete and returns the current state.

  Uniqueness of state transition records is enforced, but attempting to
  transition the same state multiple times will not result in an error.
  """
  @spec complete_setup_step(SpaceUser.t(), Space.t(), map()) ::
          {:ok, space_setup_states()} | {:error, Ecto.Changeset.t()}
  def complete_setup_step(space_user, space, params) do
    params_with_relations =
      params
      |> Map.put(:space_id, space.id)
      |> Map.put(:space_user_id, space_user.id)

    changeset =
      %SpaceSetupTransition{}
      |> SpaceSetupTransition.create_changeset(params_with_relations)

    case Repo.insert(changeset) do
      {:ok, _} ->
        get_setup_state(space)

      {:error, %Ecto.Changeset{errors: [state: _]}} ->
        get_setup_state(space)

      error ->
        error
    end
  end
end
