defmodule Level.AssetStore.Adapter do
  @moduledoc """
  The behaviour for asset store adapters.
  """

  @doc """
  Persist the blob to the store and return the filename.
  """
  @callback persist(pathname :: String.t(), bucket :: String.t(), blob :: binary()) ::
              {:ok, pathname :: String.t()} | {:error, any()}

  @doc """
  Builds the public url for an object.
  """
  @callback public_url(pathname :: String.t(), bucket :: String.t()) :: String.t()
end
