defmodule Level.Uploads do
  @moduledoc """
  Functions for interacting with user file uploads.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias Level.AssetStore
  alias Level.Repo
  alias Level.Spaces.SpaceUser
  alias Level.Upload

  @doc """
  Fetches uploads from a list of ids.
  """
  @spec get_uploads(SpaceUser.t(), [String.t()]) :: [Upload.t()] | no_return()
  def get_uploads(%SpaceUser{} = space_user, upload_ids) do
    space_user
    |> Ecto.assoc(:uploads)
    |> where([u], u.id in ^upload_ids)
    |> Repo.all()
  end

  @doc """
  Creates a new upload.
  """
  @spec create_upload(SpaceUser.t(), Plug.Upload.t()) ::
          {:ok, %{upload: Upload.t(), store: any()}}
          | {:error, :upload | :store, any(), any()}
          | {:error, atom()}
  def create_upload(%SpaceUser{} = space_user, %Plug.Upload{} = upload) do
    upload
    |> get_file_contents()
    |> store_file(space_user, upload)
  end

  defp get_file_contents(%Plug.Upload{path: path_on_disk}) do
    File.read(path_on_disk)
  end

  defp store_file({:ok, binary_data}, space_user, upload) do
    params = %{
      space_id: space_user.space_id,
      space_user_id: space_user.id,
      filename: upload.filename,
      content_type: upload.content_type,
      size: byte_size(binary_data)
    }

    Multi.new()
    |> Multi.insert(:upload, Upload.create_changeset(%Upload{}, params))
    |> Multi.run(:store, fn %{upload: %Upload{id: id, filename: filename}} ->
      AssetStore.persist_upload(id, filename, binary_data)
    end)
    |> Repo.transaction()
  end

  defp store_file(err, _, _), do: err

  @doc """
  Builds the fully-qualified URL for an upload.
  """
  @spec upload_url(Upload.t()) :: String.t()
  def upload_url(%Upload{} = upload) do
    AssetStore.upload_url(upload.id, upload.filename)
  end
end
