defmodule Level.BotsTtest do
  use Level.DataCase, async: true

  alias Level.Bots
  alias Level.Schemas.Bot

  describe "create_level_bot!/0" do
    test "creates the levelbot" do
      assert %Bot{id: bot_id, state: "ACTIVE", handle: "levelbot", display_name: "Level"} =
               Bots.create_level_bot!()
    end
  end

  describe "get_level_bot!/0" do
    test "fetches levelbot" do
      assert %Bot{handle: "levelbot"} = Bots.get_level_bot!()
    end
  end
end
