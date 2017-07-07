defmodule Bridge.Web.UrlHelpers do
  @moduledoc """
  A collection of URL helpers to assist with routing across subdomains.
  """

  alias Bridge.Web.Router.Helpers

  def signup_url(conn) do
    URI.to_string %{build_uri_from_conn(conn) |
      host: "launch.#{root_domain()}",
      path: Helpers.team_path(conn, :new)}
  end

  def team_login_url(conn, team) do
    URI.to_string %{build_uri_from_conn(conn) |
      host: "#{team.slug}.#{root_domain()}",
      path: Helpers.session_path(conn, :new)}
  end

  def team_search_url(conn) do
    URI.to_string %{build_uri_from_conn(conn) |
      host: "launch.#{root_domain()}",
      path: Helpers.team_search_path(conn, :new)}
  end

  def threads_url(conn, team) do
    URI.to_string %{build_uri_from_conn(conn) |
      host: "#{team.slug}.#{root_domain()}",
      path: Helpers.thread_path(conn, :index)}
  end

  def root_domain do
    Application.get_env(:bridge, Bridge.Web.Endpoint)[:url][:host]
  end

  defp build_uri_from_conn(conn) do
    %URI{
      scheme: Atom.to_string(conn.scheme),
      port: conn.port,
    }
  end
end
