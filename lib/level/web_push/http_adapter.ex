defmodule Level.WebPush.HttpAdapter do
  @moduledoc """
  The HTTP client for sending real web pushes.
  """

  alias Level.WebPush.Subscription

  @behaviour Level.WebPush.Adapter

  @doc """
  Sends a web push.
  """
  @spec send_web_push(String.t(), Subscription.t()) :: {:ok, any()} | {:error, atom()}
  @impl true
  def send_web_push(body, subscription) do
    WebPushEncryption.send_web_push(body, subscription)
  end
end
