defmodule Level.AssetStore do
  @moduledoc """
  Responsible for taking file uploads and storing them.
  """

  @adapter Application.get_env(:level, :asset_store)[:adapter]
  @bucket Application.get_env(:level, :asset_store)[:bucket]

  @typedoc "A Base-64 encoded data url"
  @type base64_data_url :: String.t()

  @doc """
  Uploads an avatar with a randomly-generated file name.
  """
  @spec persist_avatar(base64_data_url()) :: {:ok, filename :: String.t()} | :error
  def persist_avatar(data) do
    case decode_base64_data_url(data) do
      {:ok, binary_data} ->
        binary_data
        |> build_avatar_path()
        |> @adapter.persist(@bucket, binary_data)

      :error ->
        :error
    end
  end

  @doc """
  Generates the URL for a given avatar filename.
  """
  @spec avatar_url(String.t()) :: String.t()
  def avatar_url(pathname) do
    @adapter.public_url(pathname, @bucket)
  end

  @doc """
  Uploads a file.
  """
  @spec persist_upload(String.t(), String.t(), binary()) :: {:ok, String.t()} | {:error, any()}
  def persist_upload(unique_id, filename, binary_data) do
    unique_id
    |> build_upload_path(filename)
    |> @adapter.persist(@bucket, binary_data)
  end

  @doc """
  Builds the path for a file upload.
  """
  @spec build_upload_path(String.t(), String.t()) :: String.t()
  def build_upload_path(unique_id, filename) do
    "uploads/" <> unique_id <> "/" <> filename
  end

  @doc """
  Generates the URL for a file upload.
  """
  @spec upload_url(String.t(), String.t()) :: String.t()
  def upload_url(unique_id, filename) do
    unique_id
    |> build_upload_path(filename)
    |> @adapter.public_url(@bucket)
  end

  defp decode_base64_data_url(raw_data) do
    raw_data
    |> extract_data()
    |> decode_base64_data()
  end

  defp extract_data(raw_data) do
    Regex.run(~r/data:.*;base64,(.*)$/, raw_data)
  end

  defp decode_base64_data([_, base64_part]) do
    Base.decode64(base64_part)
  end

  defp decode_base64_data(_) do
    :error
  end

  defp build_avatar_path(binary_data) do
    binary_data
    |> image_extension()
    |> unique_filename("avatars")
  end

  defp unique_filename(extension, prefix) do
    prefix <> "/" <> Ecto.UUID.generate() <> extension
  end

  defp image_extension(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _::binary>>), do: ".png"
  defp image_extension(<<0xFF, 0xD8, _::binary>>), do: ".jpg"
end
