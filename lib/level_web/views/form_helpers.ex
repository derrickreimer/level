defmodule LevelWeb.FormHelpers do
  @moduledoc """
  Helper functions for generating form markup.
  """

  @doc """
  Generates the list of classes for a form input.

  If there are errors for the given field, the input will be outlined in red.
  """
  def input_classes(form, field) do
    if form.errors[field] do
      "input-field input-field-error"
    else
      "input-field"
    end
  end
end
