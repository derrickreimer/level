defmodule Level.GroupsTest do
  use Level.DataCase, async: true

  import Ecto.Query

  alias Level.Groups
  alias Level.Groups.Group
  alias Level.Groups.GroupBookmark
  alias Level.Groups.GroupUser

  describe "groups_base_query/2" do
    setup do
      create_user_and_space()
    end

    test "includes public non-member groups", %{
      space_user: space_user,
      space: space
    } do
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_private: false})
      {:ok, %{space_user: another_space_user}} = create_space_member(space)
      query = Groups.groups_base_query(another_space_user)
      assert Enum.any?(Repo.all(query), fn group -> group.id == group_id end)
    end

    test "includes public member groups", %{space_user: space_user} do
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_private: false})
      query = Groups.groups_base_query(space_user)
      assert Enum.any?(Repo.all(query), fn group -> group.id == group_id end)
    end

    test "excludes private non-member groups", %{
      space_user: space_user,
      space: space
    } do
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_private: true})
      {:ok, %{space_user: another_space_user}} = create_space_member(space)
      query = Groups.groups_base_query(another_space_user)
      refute Enum.any?(Repo.all(query), fn group -> group.id == group_id end)
    end
  end

  describe "groups_base_query/1" do
    setup do
      create_user_and_space()
    end

    test "includes public non-member groups", %{
      space_user: space_user,
      space: space
    } do
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_public: true})
      {:ok, %{user: another_user}} = create_space_member(space)
      query = Groups.groups_base_query(another_user)
      assert Enum.any?(Repo.all(query), fn group -> group.id == group_id end)
    end

    test "includes public member groups", %{
      user: user,
      space_user: space_user
    } do
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_public: true})
      query = Groups.groups_base_query(user)
      assert Enum.any?(Repo.all(query), fn group -> group.id == group_id end)
    end

    test "excludes private non-member groups", %{
      space_user: space_user,
      space: space
    } do
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_private: true})
      {:ok, %{user: another_user}} = create_space_member(space)
      query = Groups.groups_base_query(another_user)
      refute Enum.any?(Repo.all(query), fn group -> group.id == group_id end)
    end

    test "excludes groups in spaces to which the user does not belong", %{space_user: space_user} do
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_private: false})
      {:ok, another_user} = create_user()
      query = Groups.groups_base_query(another_user)
      refute Enum.any?(Repo.all(query), fn group -> group.id == group_id end)
    end
  end

  describe "get_group/2" do
    setup do
      create_user_and_space()
    end

    test "returns the group when public", %{space_user: space_user} do
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_private: false})
      assert {:ok, %Group{id: ^group_id}} = Groups.get_group(space_user, group_id)
    end

    test "does not return the group if it's outside the space", %{space_user: space_user} do
      {:ok, %{space_user: another_space_user}} = create_user_and_space()
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_private: false})
      assert {:error, "Group not found"} = Groups.get_group(another_space_user, group_id)
    end

    test "does not return the group if it's private and user is not a member", %{
      space_user: space_user,
      space: space
    } do
      {:ok, %{space_user: another_space_user}} = create_space_member(space)
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_private: true})
      assert {:error, "Group not found"} = Groups.get_group(another_space_user, group_id)
    end

    test "returns the group if it's private and user is a member", %{
      space_user: space_user,
      space: space
    } do
      {:ok, %{space_user: another_space_user}} = create_space_member(space)

      {:ok, %{group: %Group{id: group_id} = group}} =
        create_group(space_user, %{is_private: true})

      Groups.create_group_membership(group, another_space_user)
      assert {:ok, %Group{id: ^group_id}} = Groups.get_group(another_space_user, group_id)
    end

    test "returns an error if the group does not exist", %{space_user: space_user} do
      assert {:error, "Group not found"} = Groups.get_group(space_user, Ecto.UUID.generate())
    end
  end

  describe "create_group/3" do
    setup do
      create_user_and_space()
    end

    test "creates a group given valid data", %{space_user: space_user} do
      params = valid_group_params()
      {:ok, %{group: group}} = Groups.create_group(space_user, params)

      assert group.name == params.name
      assert group.description == params.description
      assert group.is_private == params.is_private
      assert group.creator_id == space_user.id
      assert group.space_id == space_user.space_id
    end

    test "establishes membership", %{space_user: space_user} do
      params = valid_group_params()
      {:ok, %{group: group}} = Groups.create_group(space_user, params)
      assert Repo.one(GroupUser, space_user_id: space_user.id, group_id: group.id)
    end

    test "bookmarks the group", %{space_user: space_user} do
      params = valid_group_params()
      {:ok, %{group: group, bookmarked: true}} = Groups.create_group(space_user, params)
      groups = Groups.list_bookmarked_groups(space_user)
      assert Enum.any?(groups, fn g -> g.id == group.id end)
    end

    test "returns errors given invalid data", %{space_user: space_user} do
      params = Map.put(valid_group_params(), :name, "")
      {:error, :group, changeset, _} = Groups.create_group(space_user, params)
      assert changeset.errors == [name: {"can't be blank", [validation: :required]}]
    end

    test "returns errors given duplicate name", %{space_user: space_user} do
      params = valid_group_params()
      Groups.create_group(space_user, params)
      {:error, :group, changeset, _} = Groups.create_group(space_user, params)

      assert changeset.errors == [name: {"has already been taken", []}]
    end
  end

  describe "bookmark_group/2" do
    setup do
      create_user_and_space()
    end

    test "bookmarks the group for the user", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)
      assert :ok = Groups.bookmark_group(group, space_user)
      assert Repo.get_by(GroupBookmark, group_id: group.id, space_user_id: space_user.id)

      # Gracefully handle duplicate bookmarking
      assert :ok = Groups.bookmark_group(group, space_user)
    end
  end

  describe "unbookmark_group/2" do
    setup do
      create_user_and_space()
    end

    test "unbookmarks the group for the user", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)
      Groups.bookmark_group(group, space_user)
      assert :ok = Groups.unbookmark_group(group, space_user)
      refute Repo.get_by(GroupBookmark, group_id: group.id, space_user_id: space_user.id)

      # Gracefully handle duplicate unbookmarking
      assert :ok = Groups.unbookmark_group(group, space_user)
    end
  end

  describe "list_bookmarked_groups/1" do
    setup do
      create_user_and_space()
    end

    test "includes bookmarked groups", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)
      Groups.bookmark_group(group, space_user)
      groups = Groups.list_bookmarked_groups(space_user)
      assert Enum.any?(groups, fn g -> g.id == group.id end)
    end

    test "excludes non-bookmarked groups", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)
      Groups.unbookmark_group(group, space_user)
      groups = Groups.list_bookmarked_groups(space_user)
      refute Enum.any?(groups, fn g -> g.id == group.id end)
    end

    test "excludes inaccessible bookmarked groups", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user, %{is_private: true})
      Groups.bookmark_group(group, space_user)
      Repo.delete_all(from(g in GroupUser))
      groups = Groups.list_bookmarked_groups(space_user)
      refute Enum.any?(groups, fn g -> g.id == group.id end)
    end
  end

  describe "close_group/1" do
    setup do
      create_user_and_space()
    end

    test "transitions open groups to closed", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, closed_group} = Groups.close_group(group)
      assert closed_group.state == "CLOSED"
    end
  end

  describe "get_group_membership/2" do
    setup do
      create_user_and_space()
    end

    test "fetches the group membership if user is a member", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, group_user} = Groups.get_group_membership(group, space_user)
      assert group_user.group_id == group.id
      assert group_user.space_user_id == space_user.id
    end

    test "returns an error if user is not a member", %{space_user: space_user, space: space} do
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{space_user: another_space_user}} = create_space_member(space)

      assert {:error, "The user is a not a group member"} =
               Groups.get_group_membership(group, another_space_user)
    end
  end

  describe "create_group_membership/2" do
    setup do
      create_user_and_space()
    end

    test "bookmarks the group", %{
      space_user: space_user,
      space: space
    } do
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{space_user: another_space_user}} = create_space_member(space)

      Groups.create_group_membership(group, another_space_user)

      assert Enum.any?(Groups.list_bookmarked_groups(another_space_user), fn b ->
               b.id == group.id
             end)
    end

    test "establishes a new membership if not already one", %{
      space_user: space_user,
      space: space
    } do
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{space_user: another_space_user}} = create_space_member(space)

      {:ok, %{group_user: group_user}} = Groups.create_group_membership(group, another_space_user)
      assert group_user.group_id == group.id
      assert group_user.space_user_id == another_space_user.id
    end

    test "returns an error if user is already a member", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)

      # The creator of the group is already a member, so...
      {:error, :group_user, changeset, _} = Groups.create_group_membership(group, space_user)
      assert changeset.errors == [user: {"is already a member", []}]
    end
  end
end
