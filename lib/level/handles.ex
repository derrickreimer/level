defmodule Level.Handles do
  @moduledoc """
  Management of space, user, and bot handles.
  """

  import Level.Gettext

  alias Ecto.Changeset

  @doc """
  Regex for validating handle format.
  """
  def handle_format do
    ~r/^(?>[A-Za-z][A-Za-z0-9-\.]*[A-Za-z0-9])$/
  end

  @doc """
  A changeset validation for handle format.
  """
  @spec validate_format(Changeset.t(), atom()) :: Changeset.t()
  def validate_format(changeset, field) do
    Changeset.validate_format(
      changeset,
      field,
      handle_format(),
      message: dgettext("errors", "must contain letters, numbers, and dashes only")
    )
  end
end
