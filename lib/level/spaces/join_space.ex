defmodule Level.Spaces.JoinSpace do
  @moduledoc false

  import Ecto.Query

  alias Ecto.Changeset
  alias Level.Analytics
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
  @spec perform(User.t(), Space.t(), String.t(), list()) ::
          {:ok, SpaceUser.t()} | {:error, Changeset.t()}
  def perform(user, space, role, opts \\ []) do
    params = %{
      user_id: user.id,
      space_id: space.id,
      role: role,
      first_name: user.first_name,
      last_name: user.last_name,
      handle: user.handle,
      avatar: user.avatar,
      is_demo: user.is_demo
    }

    %SpaceUser{}
    |> SpaceUser.create_changeset(params)
    |> Repo.insert()
    |> after_create(user, space, opts)
  end

  defp after_create({:ok, space_user}, user, space, opts) do
    levelbot = Levelbot.get_space_bot!(space)

    subscribe_to_default_groups(space, space_user)
    create_default_nudges(space_user)

    if !opts[:skip_welcome_message] do
      create_welcome_message(levelbot, space_user)
    end

    if !user.is_demo && !space.is_demo do
      Task.start(fn ->
        Analytics.track(user.email, "Joined a team", %{
          team_id: space.id,
          team_name: space.name,
          team_slug: space.slug,
          role: space_user.role
        })
      end)
    end

    {:ok, space_user}
  end

  defp after_create(err, _, _, _), do: err

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

  defp create_welcome_message(levelbot, space_user) do
    body = """
    Hey @#{space_user.handle} 👋

    This is what a post looks like! Here are a few writing tips:

    - You can use [Markdown](https://daringfireball.net/projects/markdown/syntax) syntax for formatting
    - **@-mention** the people that you would like to follow-up
    - **#-tag** one or more channels where the post should appear
    - Drag-and-drop files on the editor to attach them

    It’s a good idea to keep your Inbox empty whenever possible.

    When you are finished reading this post, click the green button at the top to dismiss it from your Inbox.
    """

    create_bot_post(levelbot, body)
  end

  defp create_bot_post(levelbot, body) do
    {:ok, %{post: post}} = Posts.create_post(levelbot, %{body: body, display_name: "Level"})
    {:ok, post}
  end
end
