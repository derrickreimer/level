defmodule Level.OlsonTimeZone do
  @moduledoc """
  Validation logic for Olson time zones.
  """

  import Ecto.Changeset

  def validate(changeset, field) do
    validate_inclusion(changeset, field, Timex.timezones())
  end
end
