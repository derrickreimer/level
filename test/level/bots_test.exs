defmodule Level.BotsTtest do
  use Level.DataCase, async: true

  alias Level.Bot
  alias Level.Bots

  describe "create_level_bot!/0" do
    test "creates the levelbot" do
      assert %Bot{state: "ACTIVE", handle: "levelbot", display_name: "Level"} =
               Bots.create_level_bot!()
    end
  end
end
