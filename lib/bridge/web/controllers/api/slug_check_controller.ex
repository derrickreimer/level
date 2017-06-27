defmodule Bridge.Web.API.SlugCheckController do
  use Bridge.Web, :controller

  def create(conn, %{"slug" => slug}) do
    case Bridge.Team.slug_valid?(slug) do
      {:ok} ->
        render(conn, "create.json", %{valid: true})
      {:error, %{message: message}} ->
        render(conn, "create.json", %{valid: false, message: message})
    end
  end
end
