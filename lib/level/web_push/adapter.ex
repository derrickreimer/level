defmodule Level.WebPush.Adapter do
  @moduledoc """
  The behaviour for web push adapters.
  """

  alias Level.WebPush.Subscription

  @callback send_web_push(String.t(), Subscription.t()) :: {:ok, any()} | {:error, atom()} | no_return()
end
