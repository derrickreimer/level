defmodule Level.Billing.Adapter do
  @moduledoc """
  A behaviour for the Billing adapter.
  """

  @callback create_customer(String.t()) :: {:ok, map()} | :error
  @callback create_subscription(String.t(), String.t(), integer()) :: {:ok, map()} | :error
end
