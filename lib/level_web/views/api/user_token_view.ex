defmodule LevelWeb.API.UserTokenView do
  use LevelWeb, :view

  def render("create.json", %{token: token}) do
    %{
      token: token
    }
  end
end
