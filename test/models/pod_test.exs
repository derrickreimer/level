defmodule Bridge.PodTest do
  use Bridge.ModelCase

  alias Bridge.Pod

  @valid_attrs %{name: "some content", slug: "some content", state: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Pod.changeset(%Pod{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Pod.changeset(%Pod{}, @invalid_attrs)
    refute changeset.valid?
  end
end
