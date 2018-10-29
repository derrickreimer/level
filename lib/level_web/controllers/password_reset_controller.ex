defmodule LevelWeb.PasswordResetController do
  @moduledoc false

  use LevelWeb, :controller

  plug :redirect_if_signed_in when action in [:new, :create]

  def new(conn, _) do
    render conn, "new.html"
  end

  def create(conn, %{"password_reset" => params}) do
    # TODO: actually initiate the reset
    conn
    |> redirect(to: password_reset_path(conn, :initiated))
  end

  def initiated(conn, _) do
    render conn, "initiated.html"
  end

  defp redirect_if_signed_in(conn, _opts) do
    if conn.assigns.current_user do
      conn
      |> redirect(to: main_path(conn, :index, ["spaces"]))
      |> halt()
    else
      conn
    end
  end
end
