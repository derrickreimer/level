defmodule Level.Spaces.JoinSpace do
  @moduledoc false

  import Ecto.Query

  alias Ecto.Changeset
  alias Level.Groups
  alias Level.Levelbot
  alias Level.Nudges
  alias Level.Posts
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
    _ = create_bot_welcome_message(space, space_user)

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

  defp create_bot_welcome_message(space, space_user) do
    levelbot = Levelbot.get_space_bot!(space)

    body = """
    Hey #{space_user.first_name} 👋 this is what a post looks like.

    Posts are lightweight. At a minimum, all you need is some text. But, you can also:

    - Use [Markdown](https://daringfireball.net/projects/markdown/syntax) to add formatting to your posts
    - **@-mention** people to ensure the post lands in their Inbox
    - Drag-and-drop images and file attachments

    A green tray icon at the top of post indicates it is currently in your Inbox.

    When you are finished with a post, you can dismiss it from your Inbox by **clicking on the green icon** or pressing the `e` keyboard shortcut.
    """

    {:ok, %{post: post}} = Posts.create_post(levelbot, space_user, %{body: body})
    {:ok, [post]} = Posts.mark_as_unread(space_user, [post])
    {:ok, post}
  end
end
