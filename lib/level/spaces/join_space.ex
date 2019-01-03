defmodule Level.Spaces.JoinSpace do
  @moduledoc false

  import Ecto.Query

  alias Ecto.Changeset
  alias Level.Groups
  alias Level.Nudges
  alias Level.Repo
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.User

  @doc """
  Adds a user as a member of a space.
  """
  @spec perform(User.t(), Space.t(), String.t()) :: {:ok, SpaceUser.t()} | {:error, Changeset.t()}
  def perform(user, space, role) do
    params = %{
      user_id: user.id,
      space_id: space.id,
      role: role,
      first_name: user.first_name,
      last_name: user.last_name,
      handle: user.handle,
      avatar: user.avatar
    }

    %SpaceUser{}
    |> SpaceUser.create_changeset(params)
    |> Repo.insert()
    |> after_create(space)
  end

  defp after_create({:ok, space_user}, space) do
    _ = subscribe_to_default_groups(space, space_user)
    _ = create_default_nudges(space_user)

    {:ok, space_user}
  end

  defp after_create(err, _), do: err

  defp subscribe_to_default_groups(space, space_user) do
    space
    |> list_default_groups()
    |> Enum.each(fn group -> Groups.subscribe(group, space_user) end)
  end

  defp create_default_nudges(space_user) do
    Enum.each([660, 900], fn minute ->
      Nudges.create_nudge(space_user, %{minute: minute})
    end)
  end

  defp list_default_groups(%Space{} = space) do
    space
    |> Ecto.assoc(:groups)
    |> where([g], g.is_default == true)
    |> Repo.all()
  end
end
