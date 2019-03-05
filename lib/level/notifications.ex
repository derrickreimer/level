defmodule Level.Notifications do
  @moduledoc """
  The Notifications context.
  """

  import Ecto.Query

  alias Level.Events
  alias Level.Repo
  alias Level.Schemas.Notification
  alias Level.Schemas.Post
  alias Level.Schemas.PostReaction
  alias Level.Schemas.Reply
  alias Level.Schemas.ReplyReaction
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.User

  @doc """
  A query for notifications.
  """
  @spec query(User.t()) :: Ecto.Query.t()
  def query(%User{id: user_id}) do
    from n in Notification,
      join: s in assoc(n, :space),
      join: su in assoc(n, :space_user),
      where: s.state == "ACTIVE",
      where: su.state == "ACTIVE",
      where: su.user_id == ^user_id
  end

  @spec query(SpaceUser.t(), Post.t()) :: Ecto.Query.t()
  def query(%SpaceUser{id: space_user_id}, %Post{id: post_id}) do
    topic = "post:#{post_id}"
    from n in Notification, where: n.topic == ^topic and n.space_user_id == ^space_user_id
  end

  @doc """
  Fetches notification records for given user and post.
  """
  @spec list(SpaceUser.t(), Post.t()) :: [Notification.t()]
  def list(%SpaceUser{} = space_user, %Post{} = post) do
    space_user
    |> query(post)
    |> Repo.all()
  end

  @doc """
  Records a post created notification.
  """
  @spec record_post_created(SpaceUser.t(), Post.t()) ::
          {:ok, Notification.t()} | {:error, String.t()}
  def record_post_created(%SpaceUser{} = space_user, %Post{id: post_id}) do
    data = %{"post_id" => post_id}

    space_user
    |> insert_record("POST_CREATED", "post:#{post_id}", data)
    |> after_record()
  end

  @doc """
  Records a reply created notification.
  """
  @spec record_reply_created(SpaceUser.t(), Reply.t()) ::
          {:ok, Notification.t()} | {:error, String.t()}
  def record_reply_created(%SpaceUser{} = space_user, %Reply{id: reply_id, post_id: post_id}) do
    data = %{"post_id" => post_id, "reply_id" => reply_id}

    space_user
    |> insert_record("REPLY_CREATED", "post:#{post_id}", data)
    |> after_record()
  end

  @doc """
  Records a post closed notification.
  """
  @spec record_post_closed(SpaceUser.t(), Post.t()) ::
          {:ok, Notification.t()} | {:error, String.t()}
  def record_post_closed(%SpaceUser{} = space_user, %Post{id: post_id}) do
    data = %{"post_id" => post_id}

    space_user
    |> insert_record("POST_CLOSED", "post:#{post_id}", data)
    |> after_record()
  end

  @doc """
  Records a post reopened notification.
  """
  @spec record_post_reopened(SpaceUser.t(), Post.t()) ::
          {:ok, Notification.t()} | {:error, String.t()}
  def record_post_reopened(%SpaceUser{} = space_user, %Post{id: post_id}) do
    data = %{"post_id" => post_id}

    space_user
    |> insert_record("POST_REOPENED", "post:#{post_id}", data)
    |> after_record()
  end

  @doc """
  Records a post reaction created notification.
  """
  @spec record_post_reaction_created(SpaceUser.t(), PostReaction.t()) ::
          {:ok, Notification.t()} | {:error, String.t()}
  def record_post_reaction_created(%SpaceUser{} = space_user, %PostReaction{
        id: id,
        post_id: post_id
      }) do
    data = %{"post_id" => post_id, "post_reaction_id" => id}

    space_user
    |> insert_record("POST_REACTION_CREATED", "post:#{post_id}", data)
    |> after_record()
  end

  @doc """
  Records a post reaction created notification.
  """
  @spec record_reply_reaction_created(SpaceUser.t(), ReplyReaction.t()) ::
          {:ok, Notification.t()} | {:error, String.t()}
  def record_reply_reaction_created(%SpaceUser{} = space_user, %ReplyReaction{
        id: id,
        post_id: post_id,
        reply_id: reply_id
      }) do
    data = %{"post_id" => post_id, "reply_id" => reply_id, "reply_reaction_id" => id}

    space_user
    |> insert_record("REPLY_REACTION_CREATED", "post:#{post_id}", data)
    |> after_record()
  end

  defp insert_record(space_user, event, topic, data) do
    params = %{
      space_id: space_user.space_id,
      space_user_id: space_user.id,
      event: event,
      topic: topic,
      data: data
    }

    %Notification{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert()
  end

  defp after_record({:ok, notification}) do
    Events.notification_created(notification.space_user_id, notification)
    {:ok, notification}
  end

  defp after_record(err), do: err

  @doc """
  Dismiss notifications for the given posts.
  """
  @spec dismiss(SpaceUser.t(), [Post.t()]) :: {:ok, [Post.t()]}
  def dismiss(%SpaceUser{} = space_user, posts) do
    posts
    |> Enum.each(fn post ->
      space_user
      |> query(post)
      |> Repo.update_all(set: [state: "DISMISSED"])

      post
    end)

    {:ok, posts}
  end
end
