defmodule Bridge.Web.API.UserTokenView do
  use Bridge.Web, :view

  def render("create.json", %{token: token}) do
    %{
      token: token
    }
  end
end
