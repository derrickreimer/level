defmodule Level.GroupsTest do
  use Level.DataCase, async: true

  alias Level.Groups
  alias Level.Groups.Group

  describe "list_groups_query/2" do
    setup do
      create_user_and_space()
    end

    test "returns a query that includes public non-member groups", %{user: user, space: space} do
      {:ok, %{group: %Group{id: group_id}}} = insert_group(user, %{is_public: true})
      {:ok, another_user} = insert_member(space)
      query = Groups.list_groups_query(another_user)
      result = Repo.all(query)
      assert Enum.any?(result, fn group -> group.id == group_id end)
    end

    test "returns a query that includes public member groups", %{user: user} do
      {:ok, %{group: %Group{id: group_id}}} = insert_group(user, %{is_public: true})
      query = Groups.list_groups_query(user)
      result = Repo.all(query)
      assert Enum.any?(result, fn group -> group.id == group_id end)
    end

    test "returns a query that excludes private non-member groups", %{user: user, space: space} do
      {:ok, %{group: %Group{id: group_id}}} = insert_group(user, %{is_private: true})
      {:ok, another_user} = insert_member(space)
      query = Groups.list_groups_query(another_user)
      result = Repo.all(query)
      refute Enum.any?(result, fn group -> group.id == group_id end)
    end
  end

  describe "get_group/2" do
    setup do
      create_user_and_space()
    end

    test "returns the group when public", %{user: user} do
      {:ok, %{group: %Group{id: group_id}}} = insert_group(user, %{is_private: false})
      assert {:ok, %Group{id: ^group_id}} = Groups.get_group(user, group_id)
    end

    test "does not return the group if it's outside the space", %{user: user} do
      {:ok, %{user: another_user}} = create_user_and_space()
      {:ok, %{group: %Group{id: group_id}}} = insert_group(user, %{is_private: false})
      assert {:error, "Group not found"} = Groups.get_group(another_user, group_id)
    end

    test "does not return the group if it's private and user is not a member", %{
      user: user,
      space: space
    } do
      {:ok, another_user} = insert_member(space)
      {:ok, %{group: %Group{id: group_id}}} = insert_group(user, %{is_private: true})
      assert {:error, "Group not found"} = Groups.get_group(another_user, group_id)
    end

    test "returns the group if it's private and user is a member", %{
      user: user,
      space: space
    } do
      {:ok, another_user} = insert_member(space)
      {:ok, %{group: %Group{id: group_id} = group}} = insert_group(user, %{is_private: true})
      Groups.create_group_membership(group, another_user)
      assert {:ok, %Group{id: ^group_id}} = Groups.get_group(another_user, group_id)
    end

    test "returns an error if the group does not exist", %{user: user} do
      assert {:error, "Group not found"} = Groups.get_group(user, Ecto.UUID.generate())
    end
  end

  describe "create_group/3" do
    setup do
      create_user_and_space()
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
      create_user_and_space()
    end

    test "transitions open groups to closed", %{user: user} do
      {:ok, %{group: group}} = insert_group(user)
      {:ok, closed_group} = Groups.close_group(group)
      assert closed_group.state == "CLOSED"
    end
  end

  describe "get_group_membership/2" do
    setup do
      create_user_and_space()
    end

    test "fetches the group membership if user is a member", %{user: user} do
      {:ok, %{group: group}} = insert_group(user)
      {:ok, membership} = Groups.get_group_membership(group, user)
      assert membership.group_id == group.id
      assert membership.user_id == user.id
    end

    test "returns an error if user is not a member", %{user: user, space: space} do
      {:ok, %{group: group}} = insert_group(user)
      {:ok, another_user} = insert_member(space)

      assert {:error, "The user is a not a group member"} =
               Groups.get_group_membership(group, another_user)
    end
  end

  describe "create_group_membership/2" do
    setup do
      create_user_and_space()
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
