defmodule LevelWeb.API.FileController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Files
  alias Level.Spaces

  plug :fetch_current_user_by_token

  def create(conn, %{
        "file" => %{"space_id" => space_id, "client_id" => client_id, "data" => data}
      }) do
    with {:ok, %{space_user: space_user}} <-
           Spaces.get_space(conn.assigns.current_user, space_id),
         {:ok, %{file: file}} <- Files.upload_file(space_user, data) do
      conn
      |> put_status(:created)
      |> render("create.json", %{client_id: client_id, file: file})
    else
      _ ->
        respond_with_error(conn)
    end
  end

  def create(conn, _params) do
    respond_with_error(conn)
  end

  defp respond_with_error(conn) do
    conn
    |> put_status(:unprocessable_entity)
    |> render("error.json")
  end
end
