defmodule LevelWeb.API.UploadView do
  @moduledoc false

  use LevelWeb, :view

  alias Level.Uploads

  def render("create.json", %{client_id: client_id, upload: upload}) do
    %{
      upload: %{
        id: upload.id,
        client_id: client_id,
        content_type: upload.content_type,
        filename: upload.filename,
        url: Uploads.upload_url(upload)
      }
    }
  end
end
