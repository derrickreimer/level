defmodule SprinkleWeb.API.UserViewTest do
  use SprinkleWeb.ConnCase, async: true

  alias SprinkleWeb.API.UserView

  describe "user_json/1" do
    test "includes user attributes" do
      {:ok, inserted_at, _} = DateTime.from_iso8601("2017-06-21T23:50:07Z")
      updated_at = inserted_at

      user = %Sprinkle.Teams.User{
        id: 999,
        email: "derrick@sprinkle.chat",
        username: "derrick",
        inserted_at: inserted_at,
        updated_at: updated_at
      }

      assert UserView.user_json(user) ==
        %{id: 999, email: "derrick@sprinkle.chat", username: "derrick",
          inserted_at: inserted_at, updated_at: updated_at}
    end
  end
end
