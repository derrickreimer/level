defmodule Level.Uuid do
  @moduledoc """
  Functions for validating uuids.
  """

  @regex ~r/^(\{){0,1}[0-9a-fA-F]{8}\-
    [0-9a-fA-F]{4}\-
    [0-9a-fA-F]{4}\-
    [0-9a-fA-F]{4}\-
    [0-9a-fA-F]{12}(\}){0,1}$/ix

  @doc """
  Determines if given value is a valid UUID string.
  """
  def valid?(value) do
    value =~ @regex
  end
end
