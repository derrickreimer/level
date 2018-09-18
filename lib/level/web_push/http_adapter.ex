defmodule Level.WebPush.HttpAdapter do
  @moduledoc """
  The HTTP client for sending real web pushes.
  """

  alias Level.WebPush.Payload

  @behaviour Level.WebPush.Adapter

  @impl true
  def make_request(payload, subscription) do
    payload
    |> Payload.serialize()
    |> WebPushEncryption.send_web_push(subscription)
  end
end
