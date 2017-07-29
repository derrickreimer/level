defmodule BridgeWeb.API.UserTokenView do
  use BridgeWeb, :view

  def render("create.json", %{token: token}) do
    %{
      token: token
    }
  end
end
