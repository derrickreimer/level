defmodule Bridge.PodControllerTest do
  use Bridge.ConnCase

  test "GET /pods/new", %{conn: conn} do
    conn = get conn, "/pods/new"
    assert html_response(conn, 200) =~ "Sign up for Bridge"
  end
end
