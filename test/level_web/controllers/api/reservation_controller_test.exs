defmodule LevelWeb.ReservationControllerTest do
  use LevelWeb.ConnCase, async: true

  describe "POST /api/reservations" do
    test "creates a new reservation with valid input", %{conn: conn} do
      params = %{
        email: "derrick@level.app",
        handle: "derrick"
      }

      conn =
        conn
        |> post("/api/reservations", %{"reservation" => params})

      assert response(conn, 204)
    end

    test "accepts capitals", %{conn: conn} do
      params = %{
        email: "derrick@level.app",
        handle: "DerrickReimer"
      }

      conn =
        conn
        |> post("/api/reservations", %{"reservation" => params})

      assert response(conn, 204)
    end

    test "renders validation errors with bad input", %{conn: conn} do
      params = %{
        email: "derrick@level.app",
        handle: "%&%^@"
      }

      conn =
        conn
        |> post("/api/reservations", %{"reservation" => params})

      %{"errors" => errors} = json_response(conn, 422)
      assert Enum.any?(errors, fn error -> error["attribute"] == "handle" end)
    end
  end
end
