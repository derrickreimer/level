defmodule Level.GroupsTest do
  use Level.DataCase, async: true

  alias Level.Groups
  alias Level.Groups.Group

  describe "get_group/2" do
    setup do
      insert_signup()
    end

    test "returns the group when public", %{user: user} do
      {:ok, %{group: %Group{id: group_id}}} = insert_group(user, %{is_private: false})
      assert {:ok, %Group{id: ^group_id}} = Groups.get_group(user, group_id)
    end

    test "does not return the group if it's outside the space", %{user: user} do
      {:ok, %{user: another_user}} = insert_signup()
      {:ok, %{group: %Group{id: group_id}}} = insert_group(user, %{is_private: false})
      assert {:error, "Group not found"} = Groups.get_group(another_user, group_id)
    end

    test "returns an error if the group does not exist", %{user: user} do
      assert {:error, "Group not found"} = Groups.get_group(user, Ecto.UUID.generate())
    end
  end

  describe "create_group/3" do
    setup do
      insert_signup()
    end

    test "creates a group given valid data", %{user: user} do
      params = valid_group_params()
      {:ok, %{group: group}} = Groups.create_group(user, params)

      assert group.name == params.name
      assert group.description == params.description
      assert group.is_private == params.is_private
      assert group.creator_id == user.id
      assert group.space_id == user.space_id
    end

    test "establishes membership", %{user: user} do
      params = valid_group_params()
      {:ok, %{group: group}} = Groups.create_group(user, params)
      assert Repo.one(Group, user_id: user.id, group_id: group.id)
    end

    test "returns errors given invalid data", %{user: user} do
      params = Map.put(valid_group_params(), :name, "")
      {:error, :group, changeset, _} = Groups.create_group(user, params)
      assert changeset.errors == [name: {"can't be blank", [validation: :required]}]
    end

    test "returns errors given duplicate name", %{user: user} do
      params = valid_group_params()
      Groups.create_group(user, params)
      {:error, :group, changeset, _} = Groups.create_group(user, params)

      assert changeset.errors == [name: {"has already been taken", []}]
    end
  end

  describe "close_group/1" do
    setup do
      insert_signup()
    end

    test "transitions open groups to closed", %{user: user} do
      {:ok, %{group: group}} = insert_group(user)
      {:ok, closed_group} = Groups.close_group(group)
      assert closed_group.state == "CLOSED"
    end
  end

  describe "create_group_membership/2" do
    setup do
      insert_signup()
    end

    test "establishes a new membership if not already one", %{user: user, space: space} do
      {:ok, %{group: group}} = insert_group(user)
      {:ok, another_user} = insert_member(space)

      {:ok, membership} = Groups.create_group_membership(group, another_user)
      assert membership.group_id == group.id
      assert membership.user_id == another_user.id
    end

    test "returns an error if user is already a member", %{user: user} do
      {:ok, %{group: group}} = insert_group(user)

      # The creator of the group is already a member, so...
      {:error, changeset} = Groups.create_group_membership(group, user)
      assert changeset.errors == [user: {"is already a member", []}]
    end
  end
end
