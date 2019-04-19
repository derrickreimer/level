defmodule Level.Analytics.Adapter do
  @callback identify(String.t(), map()) :: {:ok, map()} | :error
  @callback track(String.t(), String.t(), map()) :: {:ok, map()} | :error
end
