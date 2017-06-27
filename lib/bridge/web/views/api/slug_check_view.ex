defmodule Bridge.Web.API.SlugCheckView do
  use Bridge.Web, :view

  def render("create.json", %{valid: true}) do
    %{valid: true}
  end

  def render("create.json", %{valid: false, message: message}) do
    %{valid: false, message: message}
  end
end
