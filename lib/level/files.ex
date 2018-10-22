defmodule Level.Files do
  @moduledoc """
  Functions for interacting with user file uploads.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias Level.AssetStore
  alias Level.Repo
  alias Level.Schemas.File
  alias Level.Schemas.SpaceUser

  @doc """
  Fetches uploads from a list of ids.
  """
  @spec get_files(SpaceUser.t(), [String.t()]) :: [File.t()] | no_return()
  def get_files(%SpaceUser{} = space_user, file_ids) do
    space_user
    |> Ecto.assoc(:files)
    |> where([f], f.id in ^file_ids)
    |> Repo.all()
  end

  @doc """
  Creates a new upload.
  """
  @spec upload_file(SpaceUser.t(), Plug.Upload.t()) ::
          {:ok, %{file: File.t(), store: any()}}
          | {:error, :upload | :store, any(), any()}
          | {:error, atom()}
  def upload_file(%SpaceUser{} = space_user, %Plug.Upload{} = upload) do
    upload
    |> get_file_contents()
    |> store_file(space_user, upload)
  end

  defp get_file_contents(%Plug.Upload{path: path_on_disk}) do
    Elixir.File.read(path_on_disk)
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
    |> Multi.insert(:file, File.create_changeset(%File{}, params))
    |> Multi.run(:store, fn %{file: %File{id: id, filename: filename}} ->
      AssetStore.persist_file(id, filename, binary_data)
    end)
    |> Repo.transaction()
  end

  defp store_file(err, _, _), do: err

  @doc """
  Builds the fully-qualified URL for an upload.
  """
  @spec file_url(File.t()) :: String.t()
  def file_url(%File{} = file) do
    AssetStore.file_url(file.id, file.filename)
  end
end
