defmodule BridgeWeb.API.UserView do
  use BridgeWeb, :view

  def user_json(user) do
    %{
      id: user.id,
      email: user.email,
      username: user.username,
      inserted_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end
end
