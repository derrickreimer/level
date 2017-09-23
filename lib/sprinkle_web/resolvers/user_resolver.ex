defmodule SprinkleWeb.UserResolver do
  @moduledoc """
  GraphQL query resolution for users.
  """

  def drafts(user, args, _info) do
    Sprinkle.Connections.drafts(user, args, %{})
  end
end
