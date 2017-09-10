defmodule Neuron.Pagination.Edge do
  @moduledoc """
  A GraphQL-friendly struct representing an edge in a connection.
  """

  defstruct [:node, :cursor]
end
