defmodule Level.Handles do
  @moduledoc """
  Management of space, user, and bot handles.
  """

  import Level.Gettext

  alias Ecto.Changeset

  @doc """
  Regex for validating handle format.
  """
  def handle_pattern do
    ~r/^(?>[a-z0-9][a-z0-9-]*)$/ix
  end

  @doc """
  A changeset validation for handle format.
  """
  @spec validate_format(Changeset.t(), atom()) :: Changeset.t()
  def validate_format(changeset, field) do
    Changeset.validate_format(
      changeset,
      field,
      handle_pattern(),
      message: dgettext("errors", "must contain letters, numbers, and dashes only")
    )
  end
end
