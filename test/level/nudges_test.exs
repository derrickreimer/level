defmodule Level.NudgesTest do
  use Level.DataCase, async: true

  alias Ecto.Changeset
  alias Level.Nudges
  alias Level.Schemas.Nudge

  describe "create_nudge/2" do
    test "inserts a nudge given valid params" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      assert {:ok, %Nudge{}} = Nudges.create_nudge(space_user, %{minute: 660})
    end

    test "returns validation errors if minute is bad" do
      {:ok, %{space_user: space_user}} = create_user_and_space()

      assert {:error, %Changeset{errors: [minute: {"is invalid", [validation: :inclusion]}]}} =
               Nudges.create_nudge(space_user, %{minute: 6000})
    end
  end

  describe "get_nudges/1" do
    test "fetches all nudges for a given user" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, nudge} = Nudges.create_nudge(space_user, %{minute: 660})
      [returned_nudge] = Nudges.get_nudges(space_user)
      assert returned_nudge.id == nudge.id
    end
  end
end
