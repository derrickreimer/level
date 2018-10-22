defmodule Level.Schemas.PostUserLog do
  @moduledoc """
  The PostUserLog schema.
  """

  use Ecto.Schema

  alias Level.Repo
  alias Level.Schemas.Post
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "post_user_log" do
    field :event, :string

    belongs_to :space, Space
    belongs_to :post, Post
    belongs_to :space_user, SpaceUser

    timestamps(inserted_at: :occurred_at, updated_at: false)
  end

  @doc """
  Inserts a log record for marked as read.
  """
  @spec marked_as_read(Post.t(), SpaceUser.t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def marked_as_read(%Post{} = post, %SpaceUser{} = space_user) do
    insert(post, space_user, "MARKED_AS_READ")
  end

  @doc """
  Inserts a log record for marked as unread.
  """
  @spec marked_as_unread(Post.t(), SpaceUser.t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def marked_as_unread(%Post{} = post, %SpaceUser{} = space_user) do
    insert(post, space_user, "MARKED_AS_UNREAD")
  end

  @doc """
  Inserts a log record for dismissed.
  """
  @spec dismissed(Post.t(), SpaceUser.t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def dismissed(%Post{} = post, %SpaceUser{} = space_user) do
    insert(post, space_user, "DISMISSED")
  end

  @doc """
  Inserts a log record for subscribed.
  """
  @spec subscribed(Post.t(), SpaceUser.t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def subscribed(%Post{} = post, %SpaceUser{} = space_user) do
    insert(post, space_user, "SUBSCRIBED")
  end

  @doc """
  Inserts a log record for unsubscribed.
  """
  @spec unsubscribed(Post.t(), SpaceUser.t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def unsubscribed(%Post{} = post, %SpaceUser{} = space_user) do
    insert(post, space_user, "UNSUBSCRIBED")
  end

  defp insert(post, space_user, event) do
    params = %{
      event: event,
      space_id: post.space_id,
      post_id: post.id,
      space_user_id: space_user.id
    }

    %__MODULE__{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert()
  end
end
