defmodule NeuronWeb.API.UserTokenView do
  use NeuronWeb, :view

  def render("create.json", %{token: token}) do
    %{
      token: token
    }
  end
end
