defmodule Bridge.Web.API.TeamViewTest do
  use Bridge.Web.ConnCase, async: true

  alias Bridge.Web.API.TeamView
  alias Bridge.Web.API.UserView

  describe "render/2 create.json" do
    test "includes the new team" do
      user = %Bridge.User{email: "derrick@bridge.chat"}
      team = %Bridge.Team{slug: "bridge"}

      assert TeamView.render("create.json", %{user: user, team: team}) ==
        %{team: TeamView.team_json(team), user: UserView.user_json(user)}
    end
  end

  describe "render/2 errors.json" do
    test "includes attribute, message, and properties" do
      errors = [{:username, {"is required", [validation: :required]}}]
      assert TeamView.render("errors.json", %{changeset: %{errors: errors}}) ==
        %{errors: [
          %{
            attribute: :username,
            message: "is required",
            properties: %{validation: :required}
          }
        ]}
    end
  end

  describe "team_json/1" do
    test "includes team attributes" do
      {:ok, inserted_at, _} = DateTime.from_iso8601("2017-06-21T23:50:07Z")
      updated_at = inserted_at

      team = %Bridge.Team{
        id: 999,
        name: "Bridge",
        slug: "bridge",
        inserted_at: inserted_at,
        updated_at: updated_at
      }

      assert TeamView.team_json(team) ==
        %{id: 999, name: "Bridge", slug: "bridge",
          inserted_at: inserted_at, updated_at: updated_at}
    end
  end
end
