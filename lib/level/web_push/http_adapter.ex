defmodule Level.WebPush.HttpAdapter do
  @moduledoc """
  The HTTP client for sending real web pushes.
  """

  import Ecto.Query

  alias Level.Repo
  alias Level.WebPush.Payload
  alias Level.WebPush.Schema
  alias Level.WebPush.Subscription

  @behaviour Level.WebPush.Adapter

  @impl true
  def make_request(payload, subscription) do
    payload
    |> Payload.serialize()
    |> WebPushEncryption.send_web_push(subscription)
  end

  @impl true
  def delete_subscription(digest) do
    digest
    |> by_digest()
    |> Repo.delete_all()
    |> handle_delete()
  end

  defp by_digest(digest) do
    from r in Schema, where: r.digest == ^digest
  end

  defp handle_delete(_), do: :ok
end
