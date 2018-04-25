defmodule LevelWeb.UrlHelpers do
  @moduledoc """
  A collection of URL helpers to assist with routing across subdomains.
  """

  alias LevelWeb.Router.Helpers

  def signup_url(conn) do
    URI.to_string(%{
      build_uri_from_conn(conn)
      | path: Helpers.space_path(conn, :new)
    })
  end

  def space_login_url(conn, space) do
    URI.to_string(%{
      build_uri_from_conn(conn)
      | path: Helpers.session_path(conn, :new)
    })
  end

  def threads_url(conn, space) do
    URI.to_string(%{
      build_uri_from_conn(conn)
      | path: Helpers.cockpit_path(conn, :index)
    })
  end

  defp build_uri_from_conn(conn) do
    %URI{
      scheme: Atom.to_string(conn.scheme),
      port: conn.port
    }
  end
end
