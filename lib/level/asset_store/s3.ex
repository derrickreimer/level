defmodule Level.AssetStore.S3 do
  @moduledoc false

  alias ExAws.S3

  @spec persist(String.t(), String.t(), String.t()) ::
          {:ok, filename :: String.t()} | {:error, any()}
  def persist(filename, bucket, data) do
    bucket
    |> S3.put_object(filename, data, [{:acl, :public_read}])
    |> ExAws.request()
    |> handle_request(filename)
  end

  defp handle_request({:ok, _}, filename), do: {:ok, filename}
  defp handle_request(err, _filename), do: err
end
