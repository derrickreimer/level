defmodule Level.OlsonTimeZoneTest do
  use Level.DataCase, async: true

  alias Level.OlsonTimeZone

  describe "validate/2" do
    test "rejects invalid time zones" do
      time_zone = "NotAValid/TimeZone"
      types = %{time_zone: :string}

      changeset =
        {%{}, types}
        |> Ecto.Changeset.cast(%{time_zone: time_zone}, Map.keys(types))
        |> OlsonTimeZone.validate(:time_zone)

      refute changeset.valid?

      assert %Ecto.Changeset{errors: [time_zone: {"is invalid", [validation: :inclusion]}]} =
               changeset
    end

    test "accepts valid time zones" do
      time_zone = "America/Chicago"
      types = %{time_zone: :string}

      changeset =
        {%{}, types}
        |> Ecto.Changeset.cast(%{time_zone: time_zone}, Map.keys(types))
        |> OlsonTimeZone.validate(:time_zone)

      assert changeset.valid?
    end
  end
end
