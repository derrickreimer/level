defmodule LevelWeb.UrlHelpers do
  @moduledoc """
  A collection of URL helpers to assist with routing across subdomains.
  """

  alias LevelWeb.Router.Helpers
  alias LevelWeb.Endpoint

  def signup_url(conn) do
    URI.to_string(%{
      build_uri_from_conn(conn)
      | host: "launch.#{default_host()}",
        path: Helpers.space_path(conn, :new)
    })
  end

  def space_login_url(conn, space) do
    URI.to_string(%{
      build_uri_from_conn(conn)
      | host: "#{space.slug}.#{default_host()}",
        path: Helpers.session_path(conn, :new)
    })
  end

  def threads_url(conn, space) do
    URI.to_string(%{
      build_uri_from_conn(conn)
      | host: "#{space.slug}.#{default_host()}",
        path: Helpers.cockpit_path(conn, :index)
    })
  end

  def default_host do
    Keyword.get(default_url_config(), :host)
  end

  defp default_url_config do
    Application.get_env(:level, Endpoint)[:url]
  end

  defp build_uri_from_conn(conn) do
    %URI{
      scheme: Atom.to_string(conn.scheme),
      port: conn.port
    }
  end
end
