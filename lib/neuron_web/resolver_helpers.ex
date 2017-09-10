defmodule NeuronWeb.ResolverHelpers do
  @moduledoc """
  Helpers for GraphQL query resolution.
  """

  def format_errors(%Ecto.Changeset{errors: errors}) do
    Enum.map(errors, fn({attr, {msg, props}}) ->
      message = Enum.reduce props, msg, fn {k, v}, acc ->
        String.replace(acc, "%{#{k}}", to_string(v))
      end

      %{attribute: attr, message: message}
    end)
  end
end
