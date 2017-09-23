defmodule SprinkleWeb.API.UserTokenView do
  use SprinkleWeb, :view

  def render("create.json", %{token: token}) do
    %{
      token: token
    }
  end
end
