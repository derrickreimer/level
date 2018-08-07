defmodule Level.Posts.PostLog do
  @moduledoc """
  The PostLog schema.
  """

  use Ecto.Schema

  alias Level.Groups.Group
  alias Level.Posts.Post
  alias Level.Posts.Reply
  alias Level.Repo
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "post_log" do
    field :event, :string

    belongs_to :space, Space
    belongs_to :group, Group
    belongs_to :post, Post
    belongs_to :actor, SpaceUser, foreign_key: :actor_id
    belongs_to :reply, Reply

    timestamps(inserted_at: :occurred_at, updated_at: false)
  end

  @spec insert(
          :post_created,
          Level.Posts.Post.t(),
          Level.Groups.Group.t(),
          Level.Spaces.SpaceUser.t()
        ) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def insert(:post_created, %Post{} = post, %Group{} = group, %SpaceUser{} = space_user) do
    params = %{
      event: "POST_CREATED",
      space_id: post.space_id,
      group_id: group.id,
      post_id: post.id,
      actor_id: space_user.id
    }

    %__MODULE__{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert()
  end

  @spec insert(
          :reply_created,
          Level.Posts.Post.t(),
          Level.Posts.Reply.t(),
          Level.Spaces.SpaceUser.t()
        ) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def insert(:reply_created, %Post{} = post, %Reply{} = reply, %SpaceUser{} = space_user) do
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

    params = %{
      event: "REPLY_CREATED",
      space_id: post.space_id,
      group_id: group_id,
      post_id: post.id,
      reply_id: reply.id,
      actor_id: space_user.id
    }

    %__MODULE__{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert()
  end
end
