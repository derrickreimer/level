defmodule Level.AssetStore do
  @moduledoc """
  Responsible for taking file uploads and storing them.
  """

  alias Level.AssetStore.S3

  @doc """
  Uploads an avatar with a randomly-generated file name.
  """
  @spec upload_avatar(String.t()) :: {:ok, filename :: String.t()} | :error
  def upload_avatar(raw_data) do
    case decode(raw_data) do
      {:ok, binary_data} ->
        binary_data
        |> generate_avatar_filename()
        |> persist(bucket(), binary_data)

      :error ->
        :error
    end
  end

  @doc """
  Generates the URL for a given avatar filename.
  """
  @spec avatar_url(String.t()) :: String.t()
  def avatar_url(filename) do
    "https://s3.amazonaws.com/" <> bucket() <> "/" <> filename
  end

  defp bucket do
    Application.get_env(:level, :asset_store)[:bucket]
  end

  defp persist(filename, bucket, data) do
    S3.persist(filename, bucket, data)
  end

  defp decode(raw_data) do
    raw_data
    |> extract_data()
    |> decode_data()
  end

  defp extract_data(raw_data) do
    Regex.run(~r/data:.*;base64,(.*)$/, raw_data)
  end

  defp decode_data([_, base64_part]) do
    Base.decode64(base64_part)
  end

  defp decode_data(_) do
    :error
  end

  defp generate_avatar_filename(data) do
    data
    |> image_extension()
    |> unique_filename("avatars")
  end

  defp unique_filename(extension, prefix) do
    prefix <> "/" <> Ecto.UUID.generate() <> extension
  end

  defp image_extension(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _::binary>>), do: ".png"
  defp image_extension(<<0xFF, 0xD8, _::binary>>), do: ".jpg"
end
