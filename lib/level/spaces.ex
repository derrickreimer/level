defmodule Level.Spaces do
  @moduledoc """
  The Spaces context.
  """

  import Level.Gettext

  alias Ecto.Multi
  alias Level.Spaces.Member
  alias Level.Spaces.Space
  alias Level.Repo
  alias Level.Users.User

  @typedoc "The result of creating a space"
  @type create_space_result ::
          {:ok, %{space: Space.t(), member: Member.t()}}
          | {:error, :space | :member, any(), %{optional(:space | :member) => any()}}

  @doc """
  Fetches a space by id.
  """
  @spec get_space(User.t(), String.t()) ::
          {:ok, %{space: Space.t(), member: Member.t()}} | {:error, String.t()}
  def get_space(%User{} = user, id) do
    with %Space{} = space <- Repo.get(Space, id),
         %Member{} = member <- Repo.get_by(Member, user_id: user.id, space_id: space.id) do
      {:ok, %{space: space, member: member}}
    else
      _ ->
        {:error, dgettext("errors", "Space not found")}
    end
  end

  @doc """
  Fetches a space by slug.
  """
  @spec get_space_by_slug(String.t()) :: Space.t() | nil
  def get_space_by_slug(slug) do
    Repo.get_by(Space, %{slug: slug})
  end

  @doc """
  Fetches a space by slug and raises an exception if not found.
  """
  @spec get_space_by_slug!(String.t()) :: Space.t() | no_return()
  def get_space_by_slug!(slug) do
    Repo.get_by!(Space, %{slug: slug})
  end

  @doc """
  Creates a new space.
  """
  @spec create_space(User.t(), map()) :: create_space_result()
  def create_space(user, params) do
    Multi.new()
    |> Multi.insert(:space, Space.create_changeset(%Space{}, params))
    |> Multi.run(:member, fn %{space: space} -> create_owner(user, space) end)
    |> Repo.transaction()
  end

  @doc """
  Establishes a user as an owner of space.
  """
  @spec create_owner(User.t(), Space.t()) :: {:ok, Member.t()} | {:error, Ecto.Changeset.t()}
  def create_owner(user, space) do
    %Member{}
    |> Member.create_changeset(%{user_id: user.id, space_id: space.id, role: "OWNER"})
    |> Repo.insert()
  end

  @doc """
  Establishes a user as a member of space.
  """
  @spec create_member(User.t(), Space.t()) :: {:ok, Member.t()} | {:error, Ecto.Changeset.t()}
  def create_member(user, space) do
    %Member{}
    |> Member.create_changeset(%{user_id: user.id, space_id: space.id, role: "MEMBER"})
    |> Repo.insert()
  end
end
