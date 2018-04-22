defmodule Level.GroupsTest do
  use Level.DataCase, async: true

  alias Level.Groups
  alias Level.Groups.Group
  alias Level.Groups.GroupMembership

  describe "list_groups_query/2" do
    setup do
      create_user_and_space()
    end

    test "returns a query that includes public non-member groups", %{member: member, space: space} do
      {:ok, %{group: %Group{id: group_id}}} = create_group(member, %{is_public: true})
      {:ok, %{member: another_member}} = insert_member(space)
      query = Groups.list_groups_query(another_member)
      result = Repo.all(query)
      assert Enum.any?(result, fn group -> group.id == group_id end)
    end

    test "returns a query that includes public member groups", %{member: member} do
      {:ok, %{group: %Group{id: group_id}}} = create_group(member, %{is_public: true})
      query = Groups.list_groups_query(member)
      result = Repo.all(query)
      assert Enum.any?(result, fn group -> group.id == group_id end)
    end

    test "returns a query that excludes private non-member groups", %{
      member: member,
      space: space
    } do
      {:ok, %{group: %Group{id: group_id}}} = create_group(member, %{is_private: true})
      {:ok, %{member: another_member}} = insert_member(space)
      query = Groups.list_groups_query(another_member)
      result = Repo.all(query)
      refute Enum.any?(result, fn group -> group.id == group_id end)
    end
  end

  describe "get_group/2" do
    setup do
      create_user_and_space()
    end

    test "returns the group when public", %{member: member} do
      {:ok, %{group: %Group{id: group_id}}} = create_group(member, %{is_private: false})
      assert {:ok, %Group{id: ^group_id}} = Groups.get_group(member, group_id)
    end

    test "does not return the group if it's outside the space", %{member: member} do
      {:ok, %{member: another_member}} = create_user_and_space()
      {:ok, %{group: %Group{id: group_id}}} = create_group(member, %{is_private: false})
      assert {:error, "Group not found"} = Groups.get_group(another_member, group_id)
    end

    test "does not return the group if it's private and user is not a member", %{
      member: member,
      space: space
    } do
      {:ok, %{member: another_member}} = insert_member(space)
      {:ok, %{group: %Group{id: group_id}}} = create_group(member, %{is_private: true})
      assert {:error, "Group not found"} = Groups.get_group(another_member, group_id)
    end

    test "returns the group if it's private and user is a member", %{
      member: member,
      space: space
    } do
      {:ok, %{member: another_member}} = insert_member(space)
      {:ok, %{group: %Group{id: group_id} = group}} = create_group(member, %{is_private: true})
      Groups.create_group_membership(group, another_member)
      assert {:ok, %Group{id: ^group_id}} = Groups.get_group(another_member, group_id)
    end

    test "returns an error if the group does not exist", %{member: member} do
      assert {:error, "Group not found"} = Groups.get_group(member, Ecto.UUID.generate())
    end
  end

  describe "create_group/3" do
    setup do
      create_user_and_space()
    end

    test "creates a group given valid data", %{member: member} do
      params = valid_group_params()
      {:ok, %{group: group}} = Groups.create_group(member, params)

      assert group.name == params.name
      assert group.description == params.description
      assert group.is_private == params.is_private
      assert group.creator_id == member.id
      assert group.space_id == member.space_id
    end

    test "establishes membership", %{member: member} do
      params = valid_group_params()
      {:ok, %{group: group}} = Groups.create_group(member, params)
      assert Repo.one(GroupMembership, space_member_id: member.id, group_id: group.id)
    end

    test "returns errors given invalid data", %{member: member} do
      params = Map.put(valid_group_params(), :name, "")
      {:error, :group, changeset, _} = Groups.create_group(member, params)
      assert changeset.errors == [name: {"can't be blank", [validation: :required]}]
    end

    test "returns errors given duplicate name", %{member: member} do
      params = valid_group_params()
      Groups.create_group(member, params)
      {:error, :group, changeset, _} = Groups.create_group(member, params)

      assert changeset.errors == [name: {"has already been taken", []}]
    end
  end

  describe "close_group/1" do
    setup do
      create_user_and_space()
    end

    test "transitions open groups to closed", %{member: member} do
      {:ok, %{group: group}} = create_group(member)
      {:ok, closed_group} = Groups.close_group(group)
      assert closed_group.state == "CLOSED"
    end
  end

  describe "get_group_membership/2" do
    setup do
      create_user_and_space()
    end

    test "fetches the group membership if user is a member", %{member: member} do
      {:ok, %{group: group}} = create_group(member)
      {:ok, membership} = Groups.get_group_membership(group, member)
      assert membership.group_id == group.id
      assert membership.space_member_id == member.id
    end

    test "returns an error if user is not a member", %{member: member, space: space} do
      {:ok, %{group: group}} = create_group(member)
      {:ok, %{member: another_member}} = insert_member(space)

      assert {:error, "The user is a not a group member"} =
               Groups.get_group_membership(group, another_member)
    end
  end

  describe "create_group_membership/2" do
    setup do
      create_user_and_space()
    end

    test "establishes a new membership if not already one", %{member: member, space: space} do
      {:ok, %{group: group}} = create_group(member)
      {:ok, %{member: another_member}} = insert_member(space)

      {:ok, membership} = Groups.create_group_membership(group, another_member)
      assert membership.group_id == group.id
      assert membership.space_member_id == another_member.id
    end

    test "returns an error if user is already a member", %{member: member} do
      {:ok, %{group: group}} = create_group(member)

      # The creator of the group is already a member, so...
      {:error, changeset} = Groups.create_group_membership(group, member)
      assert changeset.errors == [user: {"is already a member", []}]
    end
  end
end
