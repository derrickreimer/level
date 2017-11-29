defmodule LevelWeb.API.UserTokenView do
  @moduledoc false

  use LevelWeb, :view

  def render("create.json", %{token: token}) do
    %{
      token: token
    }
  end
end
