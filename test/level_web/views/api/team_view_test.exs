defmodule LevelWeb.API.TeamViewTest do
  use LevelWeb.ConnCase, async: true

  alias LevelWeb.API.TeamView
  alias LevelWeb.API.UserView

  describe "render/2 create.json" do
    test "includes the new team" do
      user = %Level.Teams.User{email: "derrick@level.live"}
      team = %Level.Teams.Team{slug: "level"}
      redirect_url = "foo.bar"

      assert TeamView.render("create.json", %{user: user, team: team, redirect_url: redirect_url}) ==
        %{team: TeamView.team_json(team), user: UserView.user_json(user), redirect_url: redirect_url}
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

    test "interpolates properties" do
      errors = [{:username, {"must be %{count} characters", [count: 2]}}]
      assert TeamView.render("errors.json", %{changeset: %{errors: errors}}) ==
        %{errors: [
          %{
            attribute: :username,
            message: "must be 2 characters",
            properties: %{count: 2}
          }
        ]}
    end
  end

  describe "team_json/1" do
    test "includes team attributes" do
      {:ok, inserted_at, _} = DateTime.from_iso8601("2017-06-21T23:50:07Z")
      updated_at = inserted_at

      team = %Level.Teams.Team{
        id: 999,
        name: "Level",
        slug: "level",
        inserted_at: inserted_at,
        updated_at: updated_at
      }

      assert TeamView.team_json(team) ==
        %{id: 999, name: "Level", slug: "level",
          inserted_at: inserted_at, updated_at: updated_at}
    end
  end
end
