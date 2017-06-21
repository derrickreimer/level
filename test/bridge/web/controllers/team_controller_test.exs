defmodule Bridge.Web.TeamControllerTest do
  use Bridge.Web.ConnCase

  describe "GET /teams/new" do
    test "returns ok status", %{conn: conn} do
      conn = get conn, "/teams/new"
      assert html_response(conn, 200)
    end
  end
end
