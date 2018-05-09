defmodule Level.SpacesTest do
  use Level.DataCase, async: true

  alias Level.Spaces

  describe "get_space_by_slug/2" do
    setup do
      create_user_and_space()
    end

    test "returns the space if the user can access it", %{user: user, space: space} do
      {:ok, %{space: found_space, space_user: space_user}} =
        Spaces.get_space_by_slug(user, space.slug)

      assert found_space.id == space.id
      assert space_user.space_id == space.id
      assert space_user.user_id == user.id
    end

    test "returns an error if user cannot access the space", %{space: space} do
      {:ok, another_user} = create_user()

      {:error, message} = Spaces.get_space_by_slug(another_user, space.slug)
      assert message == "Space not found"
    end

    test "returns an error if the space does not exist", %{user: user} do
      {:error, message} = Spaces.get_space_by_slug(user, "idontexist")
      assert message == "Space not found"
    end
  end

  describe "get_setup_state/1" do
    setup do
      create_user_and_space()
    end

    test "returns create groups if no setup steps have been completed", %{space: space} do
      assert {:ok, :create_groups} = Spaces.get_setup_state(space)
    end

    test "returns invite users if create groups has been completed", %{
      space: space,
      space_user: space_user
    } do
      Spaces.complete_setup_step(space_user, space, %{
        state: :create_groups,
        is_skipped: false
      })

      assert {:ok, :invite_users} = Spaces.get_setup_state(space)
    end

    test "returns complete if invite users has been completed", %{
      space: space,
      space_user: space_user
    } do
      Spaces.complete_setup_step(space_user, space, %{
        state: :invite_users,
        is_skipped: false
      })

      assert {:ok, :complete} = Spaces.get_setup_state(space)
    end
  end

  describe "complete_setup_step/3" do
    setup do
      create_user_and_space()
    end

    test "inserts a transition record and returns the next state", %{
      space: space,
      space_user: space_user
    } do
      {:ok, next_state} =
        Spaces.complete_setup_step(space_user, space, %{
          state: :create_groups,
          is_skipped: false
        })

      assert Repo.get_by(Spaces.SpaceSetupTransition, %{
               space_id: space.id,
               space_user_id: space_user.id,
               state: "CREATE_GROUPS"
             })

      assert {:ok, ^next_state} = Spaces.get_setup_state(space)
    end

    test "gracefully absorbs duplicate transitions", %{space: space, space_user: space_user} do
      params = %{
        state: :create_groups,
        is_skipped: false
      }

      {:ok, _next_state} = Spaces.complete_setup_step(space_user, space, params)
      assert {:ok, _next_state} = Spaces.complete_setup_step(space_user, space, params)
    end
  end
end
