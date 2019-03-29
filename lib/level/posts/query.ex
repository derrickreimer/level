defmodule Level.Posts.Query do
  @moduledoc """
  Functions for building post queries.
  """

  import Ecto.Query

  alias Level.Schemas.GroupUser
  alias Level.Schemas.Post
  alias Level.Schemas.PostLog
  alias Level.Schemas.PostUser
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.User

  @doc """
  Builds a query for posts accessible to a particular user.
  """
  @spec base_query(User.t()) :: Ecto.Query.t()
  def base_query(%User{id: user_id} = _user) do
    query =
      from p in Post,
        join: su in SpaceUser,
        on: su.space_id == p.space_id and su.user_id == ^user_id,
        join: u in User,
        on: u.id == ^user_id

    build_base_query_with_space_user(query)
  end

  @spec base_query(SpaceUser.t()) :: Ecto.Query.t()
  def base_query(%SpaceUser{id: space_user_id} = _space_user) do
    query =
      from p in Post,
        join: su in SpaceUser,
        on: su.id == ^space_user_id,
        join: u in User,
        on: su.user_id == u.id

    build_base_query_with_space_user(query)
  end

  defp build_base_query_with_space_user(query) do
    from [p, su, u] in query,
      left_join: g in assoc(p, :groups),
      left_join: gu in GroupUser,
      on: gu.space_user_id == su.id and gu.group_id == g.id,
      left_join: pu in assoc(p, :post_users),
      on: pu.space_user_id == su.id,
      where: p.state != "DELETED",
      where: not is_nil(pu.id) or g.is_private == false or gu.access == "PRIVATE",
      distinct: p.id
  end

  @doc """
  Adds a last_activity_at field to the columns.
  """
  @spec select_last_activity_at(Ecto.Query.t()) :: Ecto.Query.t()
  def select_last_activity_at(query) do
    from [p, su, u, g, gu, pu] in query,
      left_join: pl in PostLog,
      on: pl.post_id == p.id,
      group_by: p.id,
      select_merge: %{
        last_activity_at: max(pl.occurred_at)
      }
  end

  @doc """
  Filters a posts query for posts that had activity today (in the user's TZ).
  """
  @spec where_last_active_today(Ecto.Query.t(), DateTime.t()) :: Ecto.Query.t()
  def where_last_active_today(query, now) do
    where(
      query,
      [p, su, u, g, gu, pu, pl],
      fragment(
        "date_trunc('day', timezone(?, ?::timestamptz)) = date_trunc('day', timezone(?, ?))",
        u.time_zone,
        pl.occurred_at,
        u.time_zone,
        ^now
      )
    )
  end

  @doc """
  Filters a posts query for posts that had activity after a specific point in time.
  """
  @spec where_last_active_after(Ecto.Query.t(), DateTime.t()) :: Ecto.Query.t()
  def where_last_active_after(query, timestamp) do
    from [p, su, u, g, gu, pu, pl] in query,
      where: pl.occurred_at >= ^timestamp
  end

  @doc """
  Filters a posts query for posts that are open.
  """
  @spec where_open(Ecto.Query.t()) :: Ecto.Query.t()
  def where_open(query) do
    where(query, [p, su, u, g, gu, pu], p.state == "OPEN")
  end

  @doc """
  Filters a posts query for posts that are closed.
  """
  @spec where_closed(Ecto.Query.t()) :: Ecto.Query.t()
  def where_closed(query) do
    where(query, [p, su, u, g, gu, pu], p.state == "CLOSED")
  end

  @doc """
  Filters a posts query where inbox state is unread.
  """
  @spec where_unread_in_inbox(Ecto.Query.t()) :: Ecto.Query.t()
  def where_unread_in_inbox(query) do
    where(query, [p, su, u, g, gu, pu], pu.inbox_state == "UNREAD")
  end

  @doc """
  Filters a posts query where inbox state is read.
  """
  @spec where_read_in_inbox(Ecto.Query.t()) :: Ecto.Query.t()
  def where_read_in_inbox(query) do
    where(query, [p, su, u, g, gu, pu], pu.inbox_state == "READ")
  end

  @doc """
  Filters a posts query for posts that undismissed in the inbox.
  """
  @spec where_undismissed_in_inbox(Ecto.Query.t()) :: Ecto.Query.t()
  def where_undismissed_in_inbox(query) do
    where(query, [p, su, u, g, gu, pu], pu.inbox_state in ["UNREAD", "READ"])
  end

  @doc """
  Filters a posts query for posts that undismissed in the inbox.
  """
  @spec where_dismissed_from_inbox(Ecto.Query.t()) :: Ecto.Query.t()
  def where_dismissed_from_inbox(query) do
    where(query, [p, su, u, g, gu, pu], pu.inbox_state == "DISMISSED")
  end

  @doc """
  Filters a posts query for posts that the user is following and not subscribed to.
  """
  @spec where_is_following_and_not_subscribed(Ecto.Query.t()) :: Ecto.Query.t()
  def where_is_following_and_not_subscribed(query) do
    from [p, su, u, g, gu, pu] in query,
      where: gu.state in ["SUBSCRIBED", "WATCHING"],
      where: pu.subscription_state in ["NOT_SUBSCRIBED", "UNSUBSCRIBED"] or is_nil(pu.id),
      group_by: p.id
  end

  @doc """
  Filters a posts query for posts that the user is "following".
  """
  @spec where_is_following(Ecto.Query.t()) :: Ecto.Query.t()
  def where_is_following(query) do
    from [p, su, u, g, gu, pu] in query,
      where: gu.state in ["SUBSCRIBED", "WATCHING"] or pu.subscription_state == "SUBSCRIBED",
      group_by: p.id
  end

  @doc """
  Filters a posts query for posts that are in a particular space.
  """
  @spec where_in_space(Ecto.Query.t(), String.t()) :: Ecto.Query.t()
  def where_in_space(query, space_id) do
    from [p, ...] in query,
      where: p.space_id == ^space_id
  end

  @doc """
  Filters a posts query for posts that are in a particular group.
  """
  @spec where_in_group(Ecto.Query.t(), String.t()) :: Ecto.Query.t()
  def where_in_group(query, group_id) do
    from [p, su, u, g, gu, pu] in query,
      where: g.id == ^group_id
  end

  @doc """
  Filters a posts query for posts that are authored by a particular user.
  """
  @spec where_authored_by(Ecto.Query.t(), String.t()) :: Ecto.Query.t()
  def where_authored_by(query, handle) do
    from p in query,
      left_join: u_author in assoc(p, :space_user),
      left_join: b_author in assoc(p, :space_bot),
      where: u_author.handle == ^handle or b_author.handle == ^handle
  end

  @doc """
  Filters a posts query for posts with specific user recipients.
  """
  @spec where_specific_recipients(Ecto.Query.t(), [String.t()]) :: Ecto.Query.t()
  def where_specific_recipients(query, handles) do
    # base_query =
    #   from [p, su, u, g, gu, pu] in query,
    #     inner_join: pu2 in PostUser,
    #     on: pu2.post_id == p.id,
    #     left_join: su2 in SpaceUser,
    #     on: su2.id == pu2.space_user_id and su2.handle not in ^handles,
    #     where: is_nil(g.id),
    #     where: is_nil(su2.id)
    #
    # Enum.reduce(handles, base_query, fn handle, acc ->
    #   from [p] in acc,
    #     inner_join: pu2 in PostUser,
    #     on: pu2.post_id == p.id,
    #     left_join: su2 in SpaceUser,
    #     on: su2.id == pu2.space_user_id,
    #     where: su2.handle == ^handle
    # end)

    base_query =
      from [p, su, u, g, gu, pu] in query,
        inner_join: pu2 in PostUser,
        on: pu2.post_id == p.id,
        left_join: su2 in SpaceUser,
        on: su2.id == pu2.space_user_id,
        where: is_nil(g.id),
        group_by: p.id,
        select_merge: %{recipient_handles: fragment("array_agg(?)", su2.handle)}

    from p in subquery(base_query),
      where: fragment("? @> ?::citext[]", p.recipient_handles, ^handles),
      where: fragment("? <@ ?::citext[]", p.recipient_handles, ^handles)
  end

  @doc """
  Filters a posts query for posts that are direct (not in a channel).
  """
  @spec where_is_direct(Ecto.Query.t()) :: Ecto.Query.t()
  def where_is_direct(query) do
    from [p, su, u, g] in query,
      where: is_nil(g.id)
  end

  @doc """
  Builds a count query.
  """
  @spec count(Ecto.Query.t()) :: Ecto.Query.t()
  def count(query) do
    from p in subquery(query),
      select: fragment("count(*)")
  end
end
