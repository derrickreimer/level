defmodule Level.WebPush do
  @moduledoc """
  Functions for sending web push notifications.
  """

  alias Level.WebPush.Payload
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
  @spec send_web_push(Payload.t(), Subscription.t()) ::
          {:ok, any()} | {:error, atom()} | no_return()
  def send_web_push(%Payload{} = payload, %Subscription{} = subscription) do
    payload
    |> Payload.serialize()
    |> adapter().send_web_push(subscription)
  end

  defp adapter do
    Application.get_env(:level, __MODULE__)[:adapter]
  end
end
