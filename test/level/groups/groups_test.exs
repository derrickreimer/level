defmodule Level.GroupsTest do
  use Level.DataCase

  alias Level.Groups

  describe "create_group/3" do
    setup do
      insert_signup()
    end

    test "creates a group given valid data", %{user: user, space: space} do
      params = valid_group_params()
      {:ok, group} = Groups.create_group(space, user, params)

      assert group.name == params.name
      assert group.description == params.description
      assert group.is_private == params.is_private
      assert group.creator_id == user.id
      assert group.space_id == space.id
    end
  end
end
