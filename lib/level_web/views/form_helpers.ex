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

  @doc """
  Returns the "shake" class if the given changeset contains errors.
  """
  def error_shake(%Ecto.Changeset{action: nil}), do: ""
  def error_shake(%Ecto.Changeset{valid?: false}), do: "shake"
end
