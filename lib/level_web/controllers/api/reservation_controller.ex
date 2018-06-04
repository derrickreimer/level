defmodule LevelWeb.API.ReservationController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Users

  # plug :protect_from_forgery

  def create(conn, %{"reservation" => params}) do
    case Users.create_reservation(params) do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("errors.json", %{changeset: changeset})
    end
  end
end
