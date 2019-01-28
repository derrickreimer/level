defmodule LevelWeb.PostbotControllerTest do
  use LevelWeb.ConnCase, async: true

  alias Level.Posts

  describe "POST /postbot/:space_slug/:key" do
    test "if space does not exist", %{conn: conn} do
      conn =
        conn
        |> post("/postbot/dontexist/xyz", %{"body" => "Hello world"})

      assert %{"success" => false, "reason" => "url_not_recognized"} = json_response(conn, 422)
    end

    test "if space exists but key is bad", %{conn: conn} do
      {:ok, _} = create_user_and_space(%{}, %{slug: "myspace"})

      conn =
        conn
        |> post("/postbot/myspace/xyz", %{"body" => "Hello world"})

      assert %{"success" => false, "reason" => "url_not_recognized"} = json_response(conn, 422)
    end

    test "if valid returns a success response", %{conn: conn} do
      {:ok, %{space: space, space_user: space_user, user: user}} =
        create_user_and_space(%{}, %{slug: "myspace"})

      {:ok, %{group: _}} = create_group(space_user, %{name: "peeps"})

      conn =
        conn
        |> post("/postbot/myspace/#{space.postbot_key}", %{"body" => "Hello #peeps"})

      %{"success" => true, "post_id" => post_id} = json_response(conn, 200)

      {:ok, post} = Posts.get_post(user, post_id)
      assert post.body == "Hello #peeps"
      assert post.author_display_name == nil
      assert post.avatar_initials == nil
      assert post.avatar_color == nil
    end

    test "accepts display name and avatar overrides", %{conn: conn} do
      {:ok, %{space: space, space_user: space_user, user: user}} =
        create_user_and_space(%{}, %{slug: "myspace"})

      {:ok, %{group: _}} = create_group(space_user, %{name: "peeps"})

      conn =
        conn
        |> post("/postbot/myspace/#{space.postbot_key}", %{
          "body" => "Hello #peeps",
          "display_name" => "Twitter",
          "initials" => "tw",
          "avatar_color" => "4265c7"
        })

      %{"success" => true, "post_id" => post_id} = json_response(conn, 200)

      {:ok, post} = Posts.get_post(user, post_id)
      assert post.body == "Hello #peeps"
      assert post.author_display_name == "Twitter"
      assert post.avatar_initials == "TW"
      assert post.avatar_color == "4265c7"
    end

    test "returns validation errors", %{conn: conn} do
      {:ok, %{space: space, space_user: space_user}} =
        create_user_and_space(%{}, %{slug: "myspace"})

      {:ok, %{group: _}} = create_group(space_user, %{name: "peeps"})

      conn =
        conn
        |> post("/postbot/myspace/#{space.postbot_key}", %{
          "body" => "Hello #peeps",
          "display_name" => "Twitter",
          "initials" => "foo",
          "avatar_color" => "q4265c7"
        })

      assert %{
               "errors" => [
                 %{
                   "attribute" => "avatar_color",
                   "message" => "has invalid format"
                 },
                 %{
                   "attribute" => "avatar_initials",
                   "message" => "should be at most 2 character(s)"
                 }
               ],
               "reason" => "validation_errors",
               "success" => false
             } = json_response(conn, 422)
    end
  end
end
