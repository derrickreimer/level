defmodule Level.GroupsTest do
  use Level.DataCase, async: true

  import Ecto.Query

  alias Level.Groups
  alias Level.Schemas.Group
  alias Level.Schemas.GroupBookmark
  alias Level.Schemas.GroupUser

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

      Groups.subscribe(group, another_space_user)
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
      assert Groups.get_user_state(group, space_user) == :subscribed
      assert Groups.get_user_role(group, space_user) == :owner
    end

    test "bookmarks the group", %{user: user, space_user: space_user} do
      params = valid_group_params()
      {:ok, %{group: group}} = Groups.create_group(space_user, params)
      assert Groups.is_bookmarked(user, group)
    end

    test "returns errors given invalid data", %{space_user: space_user} do
      params = Map.put(valid_group_params(), :name, "")
      {:error, changeset} = Groups.create_group(space_user, params)
      assert changeset.errors == [name: {"can't be blank", [validation: :required]}]
    end

    test "returns errors given duplicate name", %{space_user: space_user} do
      params = valid_group_params()
      Groups.create_group(space_user, params)
      {:error, changeset} = Groups.create_group(space_user, params)

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

  describe "list_bookmarks/1" do
    setup do
      create_user_and_space()
    end

    test "includes bookmarked groups", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)
      Groups.bookmark_group(group, space_user)
      groups = Groups.list_bookmarks(space_user)
      assert Enum.any?(groups, fn g -> g.id == group.id end)
    end

    test "excludes non-bookmarked groups", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)
      Groups.unbookmark_group(group, space_user)
      groups = Groups.list_bookmarks(space_user)
      refute Enum.any?(groups, fn g -> g.id == group.id end)
    end

    test "excludes inaccessible bookmarked groups", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user, %{is_private: true})
      Groups.bookmark_group(group, space_user)
      Repo.delete_all(from(g in GroupUser))
      groups = Groups.list_bookmarks(space_user)
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

  describe "is_bookmarked/2" do
    setup do
      create_user_and_space()
    end

    test "returns false if user has not bookmarked the group", %{
      user: user,
      space_user: space_user
    } do
      {:ok, %{group: group}} = create_group(space_user)
      Groups.unbookmark_group(group, space_user)
      refute Groups.is_bookmarked(user, group)
    end

    test "returns true if user has bookmarked the group", %{user: user, space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)
      Groups.bookmark_group(group, space_user)
      assert Groups.is_bookmarked(user, group)
    end
  end

  describe "grant_access/2" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user, %{is_private: true})
      {:ok, Map.merge(result, %{group: group})}
    end

    test "sets the user to not subscribed if not already a member", %{space: space, group: group} do
      {:ok, %{space_user: another_user}} = create_space_member(space)

      assert Groups.get_user_state(group, another_user) == nil
      assert {:error, _} = Groups.get_group(another_user, group.id)

      Groups.grant_access(group, another_user)

      assert {:ok, _} = Groups.get_group(another_user, group.id)
      assert Groups.get_user_state(group, another_user) == :not_subscribed
    end

    test "does not change state for subscribed users", %{space_user: space_user, group: group} do
      assert Groups.get_user_state(group, space_user) == :subscribed
      Groups.grant_access(group, space_user)
      assert Groups.get_user_state(group, space_user) == :subscribed
    end
  end

  describe "subscribe/2" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, Map.merge(result, %{group: group})}
    end

    test "sets the user to subscribed", %{space: space, group: group} do
      {:ok, %{space_user: another_user}} = create_space_member(space)
      assert Groups.get_user_state(group, another_user) == nil

      Groups.subscribe(group, another_user)
      assert Groups.get_user_state(group, another_user) == :subscribed
    end

    test "sets the user to subscribed when previously granted access", %{
      space: space,
      group: group
    } do
      {:ok, %{space_user: another_user}} = create_space_member(space)
      Groups.grant_access(group, another_user)
      assert Groups.get_user_state(group, another_user) == :not_subscribed

      Groups.subscribe(group, another_user)
      assert Groups.get_user_state(group, another_user) == :subscribed
    end
  end

  describe "unsubscribe/2" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, Map.merge(result, %{group: group})}
    end

    test "sets the user to not subscribed", %{space: space, group: group} do
      {:ok, %{space_user: another_user}} = create_space_member(space)
      assert Groups.get_user_state(group, another_user) == nil

      Groups.unsubscribe(group, another_user)
      assert Groups.get_user_state(group, another_user) == :not_subscribed
    end

    test "sets the user to not subscribed when previously subscribed", %{
      space: space,
      group: group
    } do
      {:ok, %{space_user: another_user}} = create_space_member(space)
      Groups.subscribe(group, another_user)
      assert Groups.get_user_state(group, another_user) == :subscribed

      Groups.unsubscribe(group, another_user)
      assert Groups.get_user_state(group, another_user) == :not_subscribed
    end
  end

  describe "revoke_access/2" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user, %{is_private: true})
      {:ok, Map.merge(result, %{group: group})}
    end

    test "revokes the user's access to private groups", %{
      space: space,
      group: group
    } do
      {:ok, %{space_user: another_user}} = create_space_member(space)
      Groups.subscribe(group, another_user)
      assert Groups.get_user_state(group, another_user) == :subscribed

      Groups.revoke_access(group, another_user)
      assert Groups.get_user_state(group, another_user) == nil
      assert {:error, _} = Groups.get_group(another_user, group.id)
    end
  end
end
