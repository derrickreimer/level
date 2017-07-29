defmodule Bridge.TeamTest do
  use Bridge.DataCase, async: true

  alias Bridge.Team

  describe "parse_state/1" do
    test "parses valid states" do
      assert {:ok, "ACTIVE"} == Team.parse_state("ACTIVE")
      assert {:ok, "DISABLED"} == Team.parse_state("DISABLED")
    end

    test "errors out for invalid states" do
      assert {:error, "State not recognized"} == Team.parse_state("FLOOPITY")
    end
  end

  describe "signup_changeset/2" do
    test "validates with valid data" do
      changeset = Team.signup_changeset(%Team{}, valid_signup_params())
      assert changeset.valid?
    end
  end

  describe "slug_format/0" do
    test "matches lowercase alphanumeric and dash chars" do
      assert Regex.match?(Team.slug_format, "bridge")
      assert Regex.match?(Team.slug_format, "bridge-inc")
    end

    test "does not match whitespace" do
      refute Regex.match?(Team.slug_format, "bridge inc")
    end

    test "does not match leading or trailing dashes" do
      refute Regex.match?(Team.slug_format, "bridge-")
      refute Regex.match?(Team.slug_format, "-bridge")
    end

    test "does not match special chars" do
      refute Regex.match?(Team.slug_format, "bridge$")
    end

    test "does not match uppercase chars" do
      refute Regex.match?(Team.slug_format, "Bridge")
    end
  end

  describe "Phoenix.Param.to_param implementation" do
    test "returns the slug" do
      team = %Team{id: 123, slug: "foo"}
      assert Phoenix.Param.to_param(team) == "foo"
    end
  end
end
