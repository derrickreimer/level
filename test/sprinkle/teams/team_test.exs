defmodule Sprinkle.Teams.TeamTest do
  use Sprinkle.DataCase, async: true

  alias Sprinkle.Teams.Team

  describe "signup_changeset/2" do
    test "validates with valid data" do
      changeset = Team.signup_changeset(%Team{}, valid_signup_params())
      assert changeset.valid?
    end
  end

  describe "slug_format/0" do
    test "matches lowercase alphanumeric and dash chars" do
      assert Regex.match?(Team.slug_format, "sprinkle")
      assert Regex.match?(Team.slug_format, "sprinkle-inc")
    end

    test "does not match whitespace" do
      refute Regex.match?(Team.slug_format, "sprinkle inc")
    end

    test "does not match leading or trailing dashes" do
      refute Regex.match?(Team.slug_format, "sprinkle-")
      refute Regex.match?(Team.slug_format, "-sprinkle")
    end

    test "does not match special chars" do
      refute Regex.match?(Team.slug_format, "sprinkle$")
    end

    test "does not match uppercase chars" do
      refute Regex.match?(Team.slug_format, "Sprinkle")
    end
  end

  describe "Phoenix.Param.to_param implementation" do
    test "returns the slug" do
      team = %Team{id: 123, slug: "foo"}
      assert Phoenix.Param.to_param(team) == "foo"
    end
  end
end
