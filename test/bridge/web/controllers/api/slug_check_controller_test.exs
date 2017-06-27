defmodule Bridge.Web.API.SlugCheckControllerTest do
  use Bridge.Web.ConnCase

  alias Bridge.Web.API.SlugCheckView

  describe "POST /api/slug_checks" do
    setup %{conn: conn} do
      slug = "foo"
      conn = put_req_header(conn, "content-type", "application/json")
      {:ok, %{conn: conn, slug: slug}}
    end

    test "responds when slug is available", %{conn: conn, slug: slug} do
      conn = post conn, "/api/slug_checks", %{"slug" => slug}
      assert json_response(conn, 200) ==
        render_json(SlugCheckView, "create.json", %{valid: true})
    end

    test "responds when slug is not available", %{conn: conn, slug: slug} do
      insert_signup(%{slug: slug})
      conn = post conn, "/api/slug_checks", %{"slug" => slug}
      assert json_response(conn, 200) ==
        render_json(SlugCheckView, "create.json", %{valid: false, message: "is already taken"})
    end
  end
end
