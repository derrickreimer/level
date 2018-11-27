defmodule Level.TutorialsTest do
  use Level.DataCase, async: true

  alias Level.Tutorials

  describe "update_current_step/3" do
    test "records the step" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, tutorial} = Tutorials.update_current_step(space_user, "foo", 3)
      assert tutorial.key == "foo"
      assert tutorial.current_step == 3

      {:ok, tutorial2} = Tutorials.update_current_step(space_user, "foo", 4)
      assert tutorial2.key == "foo"
      assert tutorial2.current_step == 4
    end
  end

  describe "mark_as_complete/3" do
    test "marks the tutorial as complete (idempotently)" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, tutorial} = Tutorials.mark_as_complete(space_user, "foo")
      assert tutorial.key == "foo"
      assert tutorial.is_complete == true

      {:ok, tutorial2} = Tutorials.mark_as_complete(space_user, "foo")
      assert tutorial2.is_complete == true
    end
  end

  describe "get_tutorial/2" do
    test "fetches the tutorial if it exists" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, _} = Tutorials.update_current_step(space_user, "foo", 3)

      {:ok, tutorial} = Tutorials.get_tutorial(space_user, "foo")
      assert tutorial.current_step == 3
    end

    test "returns default state if it does not exist" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, tutorial} = Tutorials.get_tutorial(space_user, "foo")
      assert tutorial.space_user_id == space_user.id
      assert tutorial.current_step == 1
      assert tutorial.is_complete == false
    end
  end
end
