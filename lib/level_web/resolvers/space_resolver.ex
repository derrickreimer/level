defmodule LevelWeb.SpaceResolver do
  @moduledoc """
  GraphQL query resolution for spaces.
  """

  def users(space, args, _info) do
    Level.Connections.users(space, args, %{})
  end
end
