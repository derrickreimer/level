defmodule LevelWeb.API.SignupErrorsControllerTest do
  use LevelWeb.ConnCase

  describe "POST /api/signup/errors" do
    setup %{conn: conn} do
      params = valid_signup_params()

      conn =
        conn
        |> put_launch_host()

      {:ok, %{conn: conn, params: params}}
    end

    test "returns empty error array if valid", %{conn: conn, params: params} do
      conn = post conn, "/api/signup/errors", %{signup: params}
      assert json_response(conn, 200) == %{"errors" => []}
    end

    test "returns errors if invalid", %{conn: conn, params: params} do
      params = Map.put(params, :slug, "Wr*ng")
      conn = post conn, "/api/signup/errors", %{signup: params}
      assert json_response(conn, 200) == %{
        "errors" => [%{
          "attribute" => "slug",
          "message" => "must be lowercase and alphanumeric",
          "properties" => %{"validation" => "format"}
        }]
      }
    end
  end
end
