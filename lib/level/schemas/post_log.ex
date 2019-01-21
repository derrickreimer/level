defmodule Level.Schemas.PostLog do
  @moduledoc """
  The PostLog schema.
  """

  use Ecto.Schema

  alias Level.Repo
  alias Level.Schemas.Group
  alias Level.Schemas.Post
  alias Level.Schemas.Reply
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "post_log" do
    field :event, :string
    field :occurred_at, :naive_datetime

    belongs_to :space, Space
    belongs_to :group, Group
    belongs_to :post, Post
    belongs_to :space_bot, SpaceBot, foreign_key: :space_bot_id
    belongs_to :space_user, SpaceUser, foreign_key: :space_user_id
    belongs_to :reply, Reply

    timestamps(inserted_at: false, updated_at: false)
  end

  @spec post_created(Post.t(), SpaceBot.t() | SpaceUser.t(), DateTime.t()) ::
          {:ok, t()} | {:error, Ecto.Changeset.t()}
  def post_created(%Post{} = post, actor, now \\ nil) do
    do_insert(
      actor,
      %{
        event: "POST_CREATED",
        space_id: post.space_id,
        post_id: post.id
      },
      now
    )
  end

  @spec post_edited(Post.t(), SpaceBot.t() | SpaceUser.t(), DateTime.t()) ::
          {:ok, t()} | {:error, Ecto.Changeset.t()}
  def post_edited(%Post{} = post, actor, now \\ nil) do
    do_insert(
      actor,
      %{
        event: "POST_EDITED",
        space_id: post.space_id,
        post_id: post.id
      },
      now
    )
  end

  @spec reply_created(Post.t(), Reply.t(), SpaceBot.t() | SpaceUser.t(), DateTime.t()) ::
          {:ok, t()} | {:error, Ecto.Changeset.t()}
  def reply_created(%Post{} = post, %Reply{} = reply, actor, now \\ nil) do
    groups =
      post
      |> Ecto.assoc(:groups)
      |> Repo.all()

    # For now, only support a post being in one group
    group_id =
      case groups do
        [%Group{id: id} | _] -> id
        _ -> nil
      end

    do_insert(
      actor,
      %{
        event: "REPLY_CREATED",
        space_id: post.space_id,
        group_id: group_id,
        post_id: post.id,
        reply_id: reply.id
      },
      now
    )
  end

  @spec reply_edited(Reply.t(), SpaceBot.t() | SpaceUser.t(), DateTime.t()) ::
          {:ok, t()} | {:error, Ecto.Changeset.t()}
  def reply_edited(%Reply{} = reply, actor, now \\ nil) do
    do_insert(
      actor,
      %{
        event: "REPLY_EDITED",
        space_id: reply.space_id,
        post_id: reply.post_id,
        reply_id: reply.id
      },
      now
    )
  end

  @spec post_closed(Post.t(), SpaceBot.t() | SpaceUser.t(), DateTime.t()) ::
          {:ok, t()} | {:error, Ecto.Changeset.t()}
  def post_closed(%Post{} = post, actor, now \\ nil) do
    do_insert(
      actor,
      %{
        event: "POST_CLOSED",
        space_id: post.space_id,
        post_id: post.id
      },
      now
    )
  end

  @spec post_reopened(Post.t(), SpaceBot.t() | SpaceUser.t(), DateTime.t()) ::
          {:ok, t()} | {:error, Ecto.Changeset.t()}
  def post_reopened(%Post{} = post, actor, now \\ nil) do
    do_insert(
      actor,
      %{
        event: "POST_REOPENED",
        space_id: post.space_id,
        post_id: post.id
      },
      now
    )
  end

  @spec post_reaction_created(Post.t(), SpaceBot.t() | SpaceUser.t(), DateTime.t()) ::
          {:ok, t()} | {:error, Ecto.Changeset.t()}
  def post_reaction_created(%Post{} = post, actor, now \\ nil) do
    do_insert(
      actor,
      %{
        event: "POST_REACTION_CREATED",
        space_id: post.space_id,
        post_id: post.id
      },
      now
    )
  end

  @spec reply_reaction_created(Reply.t(), SpaceBot.t() | SpaceUser.t(), DateTime.t()) ::
          {:ok, t()} | {:error, Ecto.Changeset.t()}
  def reply_reaction_created(%Reply{} = reply, actor, now \\ nil) do
    do_insert(
      actor,
      %{
        event: "REPLY_REACTION_CREATED",
        space_id: reply.space_id,
        post_id: reply.post_id,
        reply_id: reply.id
      },
      now
    )
  end

  defp do_insert(%SpaceUser{} = actor, params, now) do
    %__MODULE__{}
    |> Ecto.Changeset.change(Map.put(params, :occurred_at, now || DateTime.utc_now()))
    |> Ecto.Changeset.change(space_user_id: actor.id)
    |> Repo.insert()
  end

  defp do_insert(%SpaceBot{} = actor, params, now) do
    %__MODULE__{}
    |> Ecto.Changeset.change(Map.put(params, :occurred_at, now || DateTime.utc_now()))
    |> Ecto.Changeset.change(space_bot_id: actor.id)
    |> Repo.insert()
  end
end
