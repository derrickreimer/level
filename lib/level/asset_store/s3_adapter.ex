defmodule Level.AssetStore.S3Adapter do
  @moduledoc false

  alias ExAws.S3

  @behaviour Level.AssetStore.Adapter

  @impl true
  def persist(pathname, bucket, data) do
    bucket
    |> S3.put_object(pathname, data, [{:acl, :public_read}])
    |> ExAws.request()
    |> handle_request(pathname)
  end

  defp handle_request({:ok, _}, pathname), do: {:ok, pathname}
  defp handle_request(err, _filename), do: err

  @impl true
  def public_url(pathname, bucket) do
    "https://s3.amazonaws.com/" <> bucket <> "/" <> pathname
  end
end
