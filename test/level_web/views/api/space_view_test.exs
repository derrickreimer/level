defmodule LevelWeb.API.SpaceViewTest do
  use LevelWeb.ConnCase, async: true

  alias LevelWeb.API.SpaceView
  alias LevelWeb.API.UserView

  describe "render/2 create.json" do
    test "includes the new space" do
      user = %Level.Spaces.User{email: "derrick@level.live"}
      space = %Level.Spaces.Space{slug: "level"}
      redirect_url = "foo.bar"

      assert SpaceView.render("create.json", %{
               user: user,
               space: space,
               redirect_url: redirect_url
             }) ==
               %{
                 space: SpaceView.space_json(space),
                 user: UserView.user_json(user),
                 redirect_url: redirect_url
               }
    end
  end

  describe "render/2 errors.json" do
    test "includes attribute, message, and properties" do
      errors = [{:username, {"is required", [validation: :required]}}]

      assert SpaceView.render("errors.json", %{changeset: %{errors: errors}}) ==
               %{
                 errors: [
                   %{
                     attribute: :username,
                     message: "is required",
                     properties: %{validation: :required}
                   }
                 ]
               }
    end

    test "interpolates properties" do
      errors = [{:username, {"must be %{count} characters", [count: 2]}}]

      assert SpaceView.render("errors.json", %{changeset: %{errors: errors}}) ==
               %{
                 errors: [
                   %{
                     attribute: :username,
                     message: "must be 2 characters",
                     properties: %{count: 2}
                   }
                 ]
               }
    end
  end

  describe "space_json/1" do
    test "includes space attributes" do
      {:ok, inserted_at, _} = DateTime.from_iso8601("2017-06-21T23:50:07Z")
      updated_at = inserted_at

      space = %Level.Spaces.Space{
        id: 999,
        name: "Level",
        slug: "level",
        inserted_at: inserted_at,
        updated_at: updated_at
      }

      assert SpaceView.space_json(space) ==
               %{
                 id: 999,
                 name: "Level",
                 slug: "level",
                 inserted_at: inserted_at,
                 updated_at: updated_at
               }
    end
  end
end
