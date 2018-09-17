defmodule Level.WebPush.Adapter do
  @moduledoc """
  The behaviour for web push adapters.
  """

  alias Level.WebPush.Payload
  alias Level.WebPush.Subscription

  @doc """
  Sends a web push request to the subscription.
  """
  @callback make_request(Payload.t(), Subscription.t()) ::
              {:ok, any()} | {:error, atom()} | no_return()

  @doc """
  Deletes a subscription record.
  """
  @callback delete_subscription(String.t()) :: :ok | no_return()
end
