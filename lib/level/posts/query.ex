defmodule Level.Posts.Query do
  @moduledoc """
  Functions for building post queries.
  """

  import Ecto.Query

  alias Level.Schemas.GroupUser
  alias Level.Schemas.Post
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.User

  @doc """
  Builds a query for posts accessible to a particular user.
  """
  @spec base_query(User.t()) :: Ecto.Query.t()
  def base_query(%User{id: user_id} = _user) do
    from p in Post,
      join: su in SpaceUser,
      on: su.space_id == p.space_id and su.user_id == ^user_id,
      left_join: g in assoc(p, :groups),
      left_join: gu in GroupUser,
      on: gu.space_user_id == su.id and gu.group_id == g.id,
      left_join: pu in assoc(p, :post_users),
      on: pu.space_user_id == su.id,
      where: not is_nil(pu.id) or g.is_private == false or not is_nil(gu.id),
      distinct: p.id
  end

  @spec base_query(SpaceUser.t()) :: Ecto.Query.t()
  def base_query(%SpaceUser{id: space_user_id} = _space_user) do
    from p in Post,
      left_join: g in assoc(p, :groups),
      left_join: gu in GroupUser,
      on: gu.space_user_id == ^space_user_id and gu.group_id == g.id,
      left_join: pu in assoc(p, :post_users),
      on: pu.space_user_id == ^space_user_id,
      where: not is_nil(pu.id) or g.is_private == false or not is_nil(gu.id),
      distinct: p.id
  end

  @doc """
  Filters a posts query where inbox state is unread.
  """
  @spec where_is_unread(Ecto.Query.t()) :: Ecto.Query.t()
  def where_is_unread(query) do
    where(query, [p, g, gu, pu], pu.inbox_state == "UNREAD")
  end

  @doc """
  Builds a count query.
  """
  @spec count(Ecto.Query.t()) :: Ecto.Query.t()
  def count(query) do
    from [p, ...] in query,
      select: count(p.id),
      group_by: p.id
  end
end
