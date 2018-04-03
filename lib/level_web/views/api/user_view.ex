defmodule LevelWeb.API.UserView do
  @moduledoc false

  use LevelWeb, :view

  def user_json(user) do
    %{
      id: user.id,
      email: user.email,
      inserted_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end
end
