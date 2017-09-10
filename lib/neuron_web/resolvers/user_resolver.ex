defmodule NeuronWeb.UserResolver do
  @moduledoc """
  GraphQL query resolution for users.
  """

  def drafts(user, args, _info) do
    Neuron.Connections.drafts(user, args, %{})
  end
end
