defmodule LevelWeb.Util.SvgToElmController do
  @moduledoc false

  use LevelWeb, :controller

  import Level.Gettext

  plug :put_layout, "page.html"

  def index(conn, _params) do
    conn
    |> assign(:page_title, "SVG to Elm Utility")
    |> render("index.html")
  end

  def create(conn, %{"converter" => %{"svg" => raw_svg}}) do
    raw_svg
    |> Level.Svg.to_elm()
    |> respond_with_elm(conn)
  end

  defp respond_with_elm({:ok, value}, conn) do
    conn
    |> assign(:page_title, "SVG to Elm Utility")
    |> assign(:elm_output, value)
    |> render("index.html")
  end

  defp respond_with_elm({:error, _}, conn) do
    conn
    |> put_flash(:error, generic_error())
    |> render("index.html")
  end

  defp generic_error do
    dgettext(
      "errors",
      "Hmm...something went wrong. If the problem persists, please file a bug report on GitHub."
    )
  end
end
