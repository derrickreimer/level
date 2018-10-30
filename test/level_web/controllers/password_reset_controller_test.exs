defmodule LevelWeb.PasswordResetControllerTest do
  use LevelWeb.ConnCase, async: true

  alias Level.Repo
  alias Level.Users

  describe "GET /reset-password" do
    test "includes the correct heading", %{conn: conn} do
      conn =
        conn
        |> get("/reset-password")

      assert html_response(conn, 200) =~ "Reset my password"
    end

    test "redirects to spaces path if already signed in", %{conn: conn} do
      password = "$ecret$"
      {:ok, user} = create_user(%{password: password})

      signed_in_conn =
        conn
        |> post("/login", %{"session" => %{"email" => user.email, "password" => password}})

      conn =
        signed_in_conn
        |> recycle()
        |> get("/reset-password")

      assert redirected_to(conn, 302) =~ "/spaces"
    end
  end

  describe "POST /reset-password" do
    test "redirects to a check your email page", %{conn: conn} do
      conn =
        conn
        |> post("/reset-password", %{"password_reset" => %{"email" => "derrick@level.app"}})

      assert html_response(conn, 302) =~ "/reset-password/initiated"
    end
  end

  describe "GET /reset-password/initiated" do
    test "includes the correct copy", %{conn: conn} do
      conn =
        conn
        |> get("/reset-password/initiated")

      assert html_response(conn, 200) =~ "Check your email for instructions"
    end
  end

  describe "GET /reset-password/:id" do
    test "renders the form if the reset is not expired", %{conn: conn} do
      {:ok, user} = create_user()
      {:ok, reset} = Users.initiate_password_reset(user)

      conn =
        conn
        |> get("/reset-password/#{reset.id}")

      assert html_response(conn, 200) =~ "Reset my password"
    end

    test "renders a 404 if the reset is expired", %{conn: conn} do
      {:ok, user} = create_user()
      {:ok, reset} = Users.initiate_password_reset(user)

      # Expire the reset record
      reset
      |> Ecto.Changeset.change(%{expires_at: NaiveDateTime.utc_now() |> NaiveDateTime.add(-10)})
      |> Repo.update()

      conn =
        conn
        |> get("/reset-password/#{reset.id}")

      assert html_response(conn, 404)
    end
  end

  describe "PUT /reset-password/:id" do
    setup %{conn: conn} do
      {:ok, user} = create_user()
      {:ok, reset} = Users.initiate_password_reset(user)
      {:ok, %{conn: conn, user: user, reset: reset}}
    end

    test "renders errors if new password is invalid", %{conn: conn, reset: reset} do
      conn =
        conn
        |> put("/reset-password/#{reset.id}", %{"password_reset" => %{"password" => "boo"}})

      assert html_response(conn, 200) =~ "should be at least 6 character(s)"
    end

    test "redirects to the sign in if successful", %{conn: conn, reset: reset, user: user} do
      new_password = "$trongpa$$word"

      conn =
        conn
        |> put("/reset-password/#{reset.id}", %{
          "password_reset" => %{"password" => new_password}
        })

      assert redirected_to(conn, 302) =~ "/login"

      signed_in_conn =
        conn
        |> recycle()
        |> post("/login", %{"session" => %{"email" => user.email, "password" => new_password}})

      assert signed_in_conn.assigns.current_user.id == user.id
      assert redirected_to(signed_in_conn, 302) =~ "/"
    end
  end
end
