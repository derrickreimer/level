defmodule LevelWeb.PasswordResetController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Users
  alias LevelWeb.ErrorView

  plug :redirect_if_signed_in when action in [:new, :create]
  plug :fetch_password_reset when action in [:show, :update]

  def new(conn, _) do
    conn
    |> assign(:page_title, "Reset my password")
    |> render("new.html")
  end

  def create(conn, %{"password_reset" => %{"email" => email}}) do
    case Users.get_user_by_email(email) do
      {:ok, user} ->
        {:ok, _} = Users.initiate_password_reset(user)

        conn
        |> redirect(to: password_reset_path(conn, :initiated))

      _ ->
        # If the user doesn't exist, we don't want to expose that knowledge
        # to the user, so we'll just pretend we did find the user.
        conn
        |> redirect(to: password_reset_path(conn, :initiated))
    end
  end

  def initiated(conn, _) do
    render conn, "initiated.html"
  end

  def show(conn, _) do
    user = conn.assigns.password_reset.user

    conn
    |> assign(:changeset, Users.reset_password_changeset(user, %{}))
    |> assign(:page_title, "Reset my password")
    |> render("show.html")
  end

  def update(conn, %{"password_reset" => params}) do
    reset = conn.assigns.password_reset

    case Users.reset_password(reset, params["password"]) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "You password was successfully reset!")
        |> redirect(to: session_path(conn, :new))

      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> assign(:page_title, "Reset my password")
        |> render("show.html")
    end
  end

  defp fetch_password_reset(conn, _opts) do
    case Users.get_password_reset(conn.params["id"]) do
      {:ok, reset} ->
        conn
        |> assign(:password_reset, reset)

      _ ->
        conn
        |> put_status(404)
        |> put_view(ErrorView)
        |> render("404.html")
        |> halt()
    end
  end

  defp redirect_if_signed_in(conn, _opts) do
    if conn.assigns.current_user do
      conn
      |> redirect(to: main_path(conn, :index, ["teams"]))
      |> halt()
    else
      conn
    end
  end
end
