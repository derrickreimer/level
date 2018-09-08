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
          | {:error, :parse_error, Poison.ParseError.t() | Poison.DecodeError.t()}
  def parse_subscription(data) do
    Subscription.parse(data)
  end
end
