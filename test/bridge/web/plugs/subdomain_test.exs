defmodule Bridge.Web.SubdomainTest do
  use Bridge.Web.ConnCase
  alias Bridge.Web.Subdomain

  describe "validate_host/2" do
    test "raises an exception if localhost", %{conn: conn} do
      assert_raise RuntimeError, fn ->
        conn
        |> Map.put(:host, "localhost")
        |> Subdomain.validate_host
      end
    end

    test "raises an exception if host does not match config", %{conn: conn} do
      assert_raise RuntimeError, fn ->
        conn
        |> Map.put(:host, "bridgetonowhere.test")
        |> Subdomain.validate_host
      end
    end

    test "returns the conn if host matches config", %{conn: conn} do
      conn =
        conn
          |> Map.put(:host, Application.get_env(:bridge, Bridge.Web.Endpoint)[:url][:host])

      validated_conn = Subdomain.validate_host(conn)

      assert conn == validated_conn
    end
  end

  describe "extract_subdomain/2" do
    setup %{conn: conn} do
      root_domain = Application.get_env(:bridge, Bridge.Web.Endpoint)[:url][:host]
      {:ok, %{conn: conn, root_domain: root_domain}}
    end

    test "sets the subdomain to blank if there is no subdomain",
      %{conn: conn, root_domain: root_domain} do
      conn =
        conn
        |> Map.put(:host, root_domain)
        |> Subdomain.extract_subdomain

      assert conn.assigns[:subdomain] == ""
    end

    test "sets the subdomain if present",
      %{conn: conn, root_domain: root_domain} do
      conn =
        conn
        |> Map.put(:host, "foo.#{root_domain}")
        |> Subdomain.extract_subdomain

      assert conn.assigns[:subdomain] == "foo"
    end
  end
end
