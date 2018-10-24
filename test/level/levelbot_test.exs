defmodule Level.LevelbotTest do
  use Level.DataCase, async: true

  alias Level.Levelbot
  alias Level.Schemas.Bot
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser

  describe "create_bot!/0" do
    test "creates the levelbot" do
      assert %Bot{id: bot_id, state: "ACTIVE", handle: "levelbot", display_name: "Level"} =
               Levelbot.create_bot!()
    end
  end

  describe "get_bot!/0" do
    test "fetches levelbot" do
      assert %Bot{handle: "levelbot"} = Levelbot.get_bot!()
    end
  end

  describe "get_space_bot!/1" do
    test "fetches level space bot by space" do
      {:ok, %{space: %Space{id: space_id} = space}} = create_user_and_space()

      assert %SpaceBot{space_id: ^space_id, handle: "levelbot"} = Levelbot.get_space_bot!(space)
    end

    test "fetches level space bot by space user" do
      {:ok, %{space_user: %SpaceUser{space_id: space_id} = space_user}} = create_user_and_space()

      assert %SpaceBot{space_id: ^space_id, handle: "levelbot"} =
               Levelbot.get_space_bot!(space_user)
    end
  end
end
