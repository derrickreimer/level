defmodule LevelWeb.DigestControllerTest do
  use LevelWeb.ConnCase, async: true

  alias Level.DailyDigest
  alias Level.Digests
  alias Level.Digests.Digest

  describe "GET /digests/:space_id/:digest_id" do
    test "renders the digest if found", %{conn: conn} do
      {:ok, %{space: space, space_user: space_user}} = create_user_and_space()
      opts = DailyDigest.digest_options("daily", Timex.now(), "Etc/UTC")
      {:ok, %Digest{id: digest_id}} = Digests.build(space_user, [], opts)

      conn =
        conn
        |> get("/digests/#{space.id}/#{digest_id}")

      assert html_response(conn, 200) =~ "Daily Digest"
    end

    test "renders 404 if not found", %{conn: conn} do
      dummy_id = "11111111-1111-1111-1111-111111111111"

      conn =
        conn
        |> get("/digests/#{dummy_id}/#{dummy_id}")

      assert html_response(conn, 404)
    end

    test "renders 404 ids are invalid uuids", %{conn: conn} do
      conn =
        conn
        |> get("/digests/foo/bar")

      assert html_response(conn, 404)
    end
  end
end
