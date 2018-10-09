defmodule LevelWeb.API.UploadController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Spaces
  alias Level.Uploads

  plug :fetch_current_user_by_token

  def create(conn, %{
        "upload" => %{"space_id" => space_id, "client_id" => client_id, "data" => data}
      }) do
    with {:ok, %{space_user: space_user}} <-
           Spaces.get_space(conn.assigns.current_user, space_id),
         {:ok, %{upload: upload}} <- Uploads.create_upload(space_user, data) do
      conn
      |> put_status(:created)
      |> render("create.json", %{client_id: client_id, upload: upload})
    else
      # TODO: handle all the error scenarios
      _err ->
        conn
        |> put_status(:unprocessable_entity)
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
  end
end
