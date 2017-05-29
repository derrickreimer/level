defmodule Bridge.PodTest do
  use Bridge.ModelCase

  alias Bridge.Pod

  @valid_signup_params %{
    name: "Bridge, Inc.",
    slug: "bridge-inc"
  }

  describe "signup_changeset/2" do
    test "validates with valid data" do
      changeset = Pod.signup_changeset(%Pod{}, @valid_signup_params)
      assert changeset.valid?
    end

    test "sets the initial state" do
      changeset = Pod.signup_changeset(%Pod{}, @valid_signup_params)
      %{state: state} = changeset.changes

      assert state == 0
    end
  end
end
