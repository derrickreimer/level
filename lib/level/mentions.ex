defmodule Level.Mentions do
  @moduledoc """
  The Mentions context.
  """

  import Ecto.Query

  alias Level.Events
  alias Level.Groups
  alias Level.Posts
  alias Level.Repo
  alias Level.Schemas.Post
  alias Level.Schemas.Reply
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.User
  alias Level.Schemas.UserMention

  @doc """
  The pattern for matching handles in a body of text.
  """
  def mention_pattern do
    ~r/
      (?:^|\W)                     # beginning of string or non-word char
      @(\#?(?>[a-z0-9][a-z0-9-]*)) # at-handle
      (?!\/)                       # without a trailing slash
      (?=
        \.+[ \t\W]|               # dots followed by space or non-word character
        \.+$|                     # dots at end of line
        [^0-9a-zA-Z_.]|           # non-word character except dot
        $                         # end of line
      )
    /ix
  end

  @doc """
  Builds a base query for fetching individual user mentions.
  """
  @spec base_query(SpaceUser.t()) :: Ecto.Query.t()
  def base_query(%SpaceUser{id: space_user_id}) do
    from m in UserMention,
      where: m.mentioned_id == ^space_user_id,
      where: is_nil(m.dismissed_at)
  end

  @spec base_query(User.t()) :: Ecto.Query.t()
  def base_query(%User{id: user_id}) do
    from m in UserMention,
      join: su in assoc(m, :mentioned),
      where: su.user_id == ^user_id,
      where: is_nil(m.dismissed_at)
  end

  @doc """
  Record mentions from the body of a post.
  """
  @spec record(SpaceUser.t(), Post.t()) :: {:ok, [String.t()]}
  def record(%SpaceUser{} = author, %Post{body: body} = post) do
    do_record(body, post, nil, author)
  end

  @spec record(SpaceUser.t(), Post.t(), Reply.t()) :: {:ok, %{space_users: [String.t()]}}
  def record(%SpaceUser{} = author, %Post{} = post, %Reply{id: reply_id, body: body}) do
    do_record(body, post, reply_id, author)
  end

  defp do_record(body, post, reply_id, author) do
    mention_pattern()
    |> Regex.scan(body, capture: :all_but_first)
    |> process_handles(post, reply_id, author)
  end

  defp process_handles(nil, _, _, _) do
    {:ok, %{space_users: [], groups: []}}
  end

  defp process_handles(handles, post, reply_id, author) do
    lower_handles =
      handles
      |> Enum.map(fn [handle] -> String.downcase(handle) end)
      |> Enum.uniq()

    channel_names =
      lower_handles
      |> Enum.flat_map(fn
        "#" <> name -> [name]
        _ -> []
      end)

    space_user_query =
      from su in SpaceUser,
        where: su.space_id == ^post.space_id,
        where: fragment("lower(?)", su.handle) in ^lower_handles

    {:ok, space_users} =
      space_user_query
      |> Repo.all()
      |> insert_batch(post, reply_id, author.id)

    group_query =
      from [g, gu] in Groups.groups_base_query(author),
        where: g.name in ^channel_names

    groups = Repo.all(group_query)
    {:ok, %{space_users: space_users, groups: groups}}
  end

  defp insert_batch(mentioned_users, post, reply_id, author_id) do
    Enum.each(mentioned_users, fn %SpaceUser{id: mentioned_id} ->
      params = %{
        space_id: post.space_id,
        post_id: post.id,
        reply_id: reply_id,
        mentioner_id: author_id,
        mentioned_id: mentioned_id
      }

      %UserMention{}
      |> Ecto.Changeset.change(params)
      |> Repo.insert()
    end)

    {:ok, mentioned_users}
  end

  @doc """
  Dismisses all mentions for given posts.
  """
  @spec dismiss_all(SpaceUser.t(), [String.t()]) :: {:ok, [Post.t()]} | no_return()
  def dismiss_all(%SpaceUser{} = space_user, post_ids) do
    space_user
    |> base_query()
    |> where([m], m.post_id in ^post_ids)
    |> exclude(:select)
    |> Repo.update_all(set: [dismissed_at: naive_now()])
    |> handle_dismiss_all(space_user, post_ids)
  end

  defp handle_dismiss_all(_, %SpaceUser{id: space_user_id} = space_user, post_ids) do
    {:ok, posts} = Posts.get_posts(space_user, post_ids)

    Enum.each(posts, fn post ->
      Events.mentions_dismissed(space_user_id, post)
    end)

    {:ok, posts}
  end

  # Fetch the current time in `naive_datetime` format
  defp naive_now do
    DateTime.utc_now() |> DateTime.to_naive()
  end
end
