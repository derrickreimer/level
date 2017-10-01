defmodule Level.Connections do
  @moduledoc """
  A context for exposing connections between nodes.
  """

  @doc """
  Fetch users belonging to given space.
  """
  def users(space, args, context \\ %{}) do
    Level.Connections.Users.get(space, args, context)
  end

  @doc """
  Fetch drafts belonging to a given user.
  """
  def drafts(user, args, context \\ %{}) do
    Level.Connections.Drafts.get(user, args, context)
  end
end
