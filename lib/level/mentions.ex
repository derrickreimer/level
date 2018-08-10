defmodule Level.Mentions do
  @moduledoc """
  The Mentions context.
  """

  import Ecto.Query

  alias Level.Posts.Post
  alias Level.Repo
  alias Level.Spaces.SpaceUser
  alias Level.Mentions.UserMention
  alias Level.Mentions.GroupedUserMention

  defmacro aggregate_ids(column) do
    quote do
      fragment("array_agg(?) FILTER (WHERE ? IS NOT NULL)", unquote(column), unquote(column))
    end
  end

  @doc """
  The pattern for matching handles in a body of text.
  """
  def handle_pattern do
    ~r/
      (?:^|\W)                    # beginning of string or non-word char
      @((?>[a-z0-9][a-z0-9-]*))   # at-handle
      (?!\/)                      # without a trailing slash
      (?=
        \.+[ \t\W]|               # dots followed by space or non-word character
        \.+$|                     # dots at end of line
        [^0-9a-zA-Z_.]|           # non-word character except dot
        $                         # end of line
      )
    /ix
  end

  @doc """
  Builds a base query for fetching grouped user mentions.
  """
  @spec base_query(SpaceUser.t()) :: Ecto.Query.t()
  def base_query(%SpaceUser{id: space_user_id}) do
    from m in {"user_mentions", GroupedUserMention},
      where: m.mentioned_id == ^space_user_id,
      where: is_nil(m.dismissed_at),
      group_by: [m.mentioned_id, m.post_id],
      select: %{
        struct(m, [:post_id, :mentioned_id])
        | reply_ids: aggregate_ids(m.reply_id),
          mentioner_ids: aggregate_ids(m.mentioner_id),
          last_occurred_at: max(m.occurred_at)
      }
  end

  @doc """
  Record mentions from the body of a post.
  """
  def record(%Post{} = post) do
    handle_pattern()
    |> Regex.run(post.body, capture: :all_but_first)
    |> process_handles(post)
  end

  defp process_handles(nil, _) do
    {:ok, []}
  end

  defp process_handles(handles, %Post{} = post) do
    lower_handles =
      handles
      |> Enum.map(fn handle -> String.downcase(handle) end)
      |> Enum.uniq()

    query =
      from su in SpaceUser,
        where: su.space_id == ^post.space_id,
        where: fragment("lower(?)", su.handle) in ^lower_handles,
        select: su.id

    query
    |> Repo.all()
    |> insert_batch(post)
  end

  defp insert_batch(mentioned_ids, %Post{} = post) do
    now = DateTime.utc_now() |> DateTime.to_naive()

    params =
      Enum.map(mentioned_ids, fn mentioned_id ->
        %{
          space_id: post.space_id,
          post_id: post.id,
          reply_id: nil,
          mentioner_id: post.space_user_id,
          mentioned_id: mentioned_id,
          occurred_at: now,
          updated_at: now
        }
      end)

    Repo.insert_all(UserMention, params)
    {:ok, mentioned_ids}
  end
end
