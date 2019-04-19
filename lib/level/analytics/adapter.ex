defmodule Level.Analytics.Adapter do
  @moduledoc """
  A behaviour for the Analytics adapter.
  """

  @callback identify(String.t(), map()) :: {:ok, map()} | :error
  @callback track(String.t(), String.t(), map()) :: {:ok, map()} | :error
end
