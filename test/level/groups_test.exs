defmodule Level.GroupsTest do
  use Level.DataCase

  alias Level.Groups

  describe "create_group/3" do
    setup do
      insert_signup()
    end

    test "creates a group given valid data", %{user: user} do
      params = valid_group_params()
      {:ok, group} = Groups.create_group(user, params)

      assert group.name == params.name
      assert group.description == params.description
      assert group.is_private == params.is_private
      assert group.creator_id == user.id
      assert group.space_id == user.space_id
    end

    test "returns errors given invalid data", %{user: user} do
      params = Map.put(valid_group_params(), :name, "")
      {:error, changeset} = Groups.create_group(user, params)
      assert changeset.errors == [name: {"can't be blank", [validation: :required]}]
    end

    test "returns errors given duplicate name", %{user: user} do
      params = valid_group_params()
      Groups.create_group(user, params)
      {:error, changeset} = Groups.create_group(user, params)

      assert changeset.errors == [name: {"has already been taken", []}]
    end
  end

  describe "close_group/1" do
    setup do
      insert_signup()
    end

    test "transitions open groups to closed", %{user: user} do
      {:ok, group} = insert_group(user)
      {:ok, closed_group} = Groups.close_group(group)
      assert closed_group.state == "CLOSED"
    end
  end
end
