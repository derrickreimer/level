defmodule Level.Posts.UpdateReply do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Level.Events
  alias Level.Posts
  alias Level.Posts.PostLog
  alias Level.Posts.Reply
  alias Level.ReplyVersion
  alias Level.Repo
  alias Level.Spaces.SpaceUser

  @spec perform(SpaceUser.t(), Reply.t(), map()) ::
          {:ok, %{original_reply: Reply.t(), updated_reply: Reply.t(), version: ReplyVersion.t()}}
          | {:error, :unauthorized}
          | {:error, atom(), any(), map()}
  def perform(%SpaceUser{} = author, %Reply{} = reply, params) do
    author
    |> Posts.can_edit?(reply)
    |> after_authorization(author, reply, params)
  end

  defp after_authorization(true, author, reply, params) do
    Multi.new()
    |> fetch_reply_with_lock(reply.id)
    |> store_version()
    |> update_reply(params)
    |> log(author)
    |> Repo.transaction()
    |> after_transaction()
  end

  defp after_authorization(false, _, _, _) do
    {:error, :unauthorized}
  end

  # Obtain a row-level lock on the reply in question, so
  # that we can safely insert a version record and update
  # the value in place without race conditions
  defp fetch_reply_with_lock(multi, reply_id) do
    Multi.run(multi, :original_reply, fn _ ->
      query = from r in Reply, where: r.id == ^reply_id, lock: "FOR UPDATE"

      query
      |> Repo.one()
      |> handle_fetch_with_lock()
    end)
  end

  defp handle_fetch_with_lock(%Reply{} = reply), do: {:ok, reply}
  defp handle_fetch_with_lock(_), do: {:error, :reply_load_error}

  defp update_reply(multi, params) do
    Multi.run(multi, :updated_reply, fn %{original_reply: original_reply} ->
      original_reply
      |> Reply.update_changeset(params)
      |> Repo.update()
    end)
  end

  defp store_version(multi) do
    Multi.run(multi, :previous_version, fn %{original_reply: original_reply} ->
      params = %{
        space_id: original_reply.space_id,
        author_id: original_reply.space_user_id,
        reply_id: original_reply.id,
        body: original_reply.body
      }

      %ReplyVersion{}
      |> ReplyVersion.create_changeset(params)
      |> Repo.insert()
    end)
  end

  defp log(multi, author) do
    Multi.run(multi, :log, fn %{updated_reply: reply} ->
      PostLog.reply_edited(reply, author)
    end)
  end

  defp after_transaction({:ok, result}) do
    Events.reply_updated(result.updated_reply.post_id, result.updated_reply)
    {:ok, result}
  end

  defp after_transaction(err), do: err
end
