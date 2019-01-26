defmodule LevelWeb.PostbotControllerTest do
  use LevelWeb.ConnCase, async: true

  describe "POST /postbot/:space_slug/:key" do
    test "if space does not exist", %{conn: conn} do
      conn =
        conn
        |> post("/postbot/dontexist/xyz", %{"body" => "Hello world"})

      assert %{"success" => false, "reason" => "url_not_recognized"} = json_response(conn, 422)
    end

    test "if space exists but key is bad", %{conn: conn} do
      {:ok, _} = create_user_and_space(%{}, %{slug: "posty"})

      conn =
        conn
        |> post("/postbot/posty/xyz", %{"body" => "Hello world"})

      assert %{"success" => false, "reason" => "url_not_recognized"} = json_response(conn, 422)
    end

    test "if body is empty", %{conn: conn} do
      {:ok, %{space: space}} = create_user_and_space(%{}, %{slug: "posty"})

      conn =
        conn
        |> post("/postbot/posty/#{space.postbot_key}", %{})

      assert %{"success" => false, "reason" => "body_is_required"} = json_response(conn, 422)
    end

    test "if url is valid", %{conn: conn} do
      {:ok, %{space: space}} = create_user_and_space(%{}, %{slug: "posty"})

      conn =
        conn
        |> post("/postbot/posty/#{space.postbot_key}", %{"body" => "Hello world"})

      assert %{"success" => true} = json_response(conn, 200)
    end
  end
end
