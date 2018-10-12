defmodule LevelWeb.API.FileView do
  @moduledoc false

  use LevelWeb, :view

  alias Level.Files

  def render("create.json", %{client_id: client_id, file: file}) do
    %{
      file: %{
        id: file.id,
        client_id: client_id,
        content_type: file.content_type,
        filename: file.filename,
        url: Files.file_url(file)
      }
    }
  end

  def render("error.json", _) do
    %{}
  end
end
