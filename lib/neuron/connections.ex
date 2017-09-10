defmodule Neuron.Connections do
  @moduledoc """
  A context for exposing connections between nodes.
  """

  @doc """
  Fetch users belonging to given team.
  """
  def users(team, args, context \\ %{}) do
    Neuron.Connections.Users.get(team, args, context)
  end

  @doc """
  Fetch drafts belonging to a given user.
  """
  def drafts(user, args, context \\ %{}) do
    Neuron.Connections.Drafts.get(user, args, context)
  end
end
