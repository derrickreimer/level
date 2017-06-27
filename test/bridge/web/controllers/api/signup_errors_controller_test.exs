defmodule Bridge.Web.API.SignupErrorsControllerTest do
  use Bridge.Web.ConnCase

  describe "GET /api/signup/errors" do
    setup %{conn: conn} do
      params = valid_signup_params()
      {:ok, %{conn: conn, params: params}}
    end

    test "returns empty error array if valid", %{conn: conn, params: params} do
      conn = get conn, "/api/signup/errors", params
      assert json_response(conn, 200) == %{"errors" => []}
    end

    test "returns errors if invalid", %{conn: conn, params: params} do
      params = Map.put(params, :slug, "Wr*ng")
      conn = get conn, "/api/signup/errors", params
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
