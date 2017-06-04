defmodule Bridge.PodTest do
  use Bridge.ModelCase, async: true

  alias Bridge.Pod

  describe "signup_changeset/2" do
    test "validates with valid data" do
      changeset = Pod.signup_changeset(%Pod{}, valid_signup_params())
      assert changeset.valid?
    end

    test "sets the initial state" do
      changeset = Pod.signup_changeset(%Pod{}, valid_signup_params())
      %{state: state} = changeset.changes

      assert state == 0
    end
  end

  describe "slug_format/0" do
    test "matches lowercase alphanumeric and dash chars" do
      assert Regex.match?(Pod.slug_format, "bridge")
      assert Regex.match?(Pod.slug_format, "bridge-inc")
    end

    test "does not match whitespace" do
      refute Regex.match?(Pod.slug_format, "bridge inc")
    end

    test "does not match leading or trailing dashes" do
      refute Regex.match?(Pod.slug_format, "bridge-")
      refute Regex.match?(Pod.slug_format, "-bridge")
    end

    test "does not match special chars" do
      refute Regex.match?(Pod.slug_format, "bridge$")
    end

    test "does not match uppercase chars" do
      refute Regex.match?(Pod.slug_format, "Bridge")
    end
  end

  describe "Phoenix.Param.to_param implementation" do
    test "returns the slug" do
      pod = %Pod{id: 123, slug: "foo"}
      assert Phoenix.Param.to_param(pod) == "foo"
    end
  end
end
