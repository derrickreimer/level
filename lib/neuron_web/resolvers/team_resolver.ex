defmodule NeuronWeb.TeamResolver do
  @moduledoc """
  GraphQL query resolution for teams.
  """

  def users(team, args, _info) do
    Neuron.Connections.users(team, args, %{})
  end
end
