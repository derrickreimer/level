defmodule Level.AssetStore.S3 do
  @moduledoc false

  alias ExAws.S3

  @doc """
  Persists the file to S3.
  """
  @spec persist(String.t(), String.t(), String.t()) :: {:ok, any()} | {:error, any()}
  def persist(filename, bucket, data) do
    S3.put_object(bucket, filename, data, [{:acl, :public_read}])
    |> ExAws.request()
  end
end
