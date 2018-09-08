defmodule Level.WebPush do
  @moduledoc """
  Functions for sending web push notifications.
  """

  alias Level.WebPush.Subscription

  @doc """
  Parses raw stringified JSON subscription data.
  """
  @spec parse_subscription(String.t()) ::
          {:ok, Subscription.t()}
          | {:error, :invalid_keys}
          | {:error, :parse_error}
  def parse_subscription(data) do
    Subscription.parse(data)
  end

  @doc """
  Sends a notification to a particular subscription.
  """
  @spec send_notification(Subscription.t(), String.t()) ::
          {:ok, any()} | {:error, atom()} | no_return()
  def send_notification(%Subscription{} = subscription, text) do
    body =
      %{text: text}
      |> Poison.encode!()

    WebPushEncryption.send_web_push(body, subscription)
  end
end
