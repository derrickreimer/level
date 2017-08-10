defmodule Bridge.Connections do
  @moduledoc """
  A context for exposing connections between nodes.
  """

  @doc """
  Fetch users belonging to given team.
  """
  def users(team, args, context \\ %{}) do
    Bridge.Connections.Users.get(team, args, context)
  end
end
