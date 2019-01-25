defmodule Level.PostbotTest do
  use Level.DataCase, async: true

  alias Level.Postbot
  alias Level.Schemas.Bot
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser

  describe "create_bot!/0" do
    test "creates the postbot" do
      assert %Bot{state: "ACTIVE", handle: "postbot", display_name: "Postbot"} =
               Postbot.create_bot!()
    end
  end

  describe "get_bot!/0" do
    test "fetches postbot" do
      assert %Bot{handle: "postbot"} = Postbot.get_bot!()
    end
  end

  describe "get_space_bot/1" do
    test "fetches by space" do
      {:ok, %{space: %Space{id: space_id} = space}} = create_user_and_space()
      {:ok, _} = Postbot.install_bot(space)

      assert %SpaceBot{space_id: ^space_id, handle: "postbot"} = Postbot.get_space_bot(space)
    end

    test "fetches by space user" do
      {:ok, %{space: space, space_user: %SpaceUser{space_id: space_id} = space_user}} =
        create_user_and_space()

      {:ok, _} = Postbot.install_bot(space)

      assert %SpaceBot{space_id: ^space_id, handle: "postbot"} = Postbot.get_space_bot(space_user)
    end

    test "returns nil if not installed" do
      {:ok, %{space: space}} = create_user_and_space()
      assert Postbot.get_space_bot(space) == nil
    end
  end
end
