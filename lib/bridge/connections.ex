defmodule Bridge.Connections do
  @moduledoc """
  A context for exposing connections between nodes.
  """

  @doc """
  Fetch users belonging to given team.
  """
  def users(team, args, info) do
    Bridge.Connections.Users.get(team, args, info)
  end
end
