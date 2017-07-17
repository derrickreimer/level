defmodule Bridge.Web.UrlHelpers do
  @moduledoc """
  A collection of URL helpers to assist with routing across subdomains.
  """

  alias Bridge.Web.Router.Helpers
  alias Bridge.Web.Endpoint

  def signup_url(conn) do
    URI.to_string %{build_uri_from_conn(conn) |
      host: "launch.#{default_host()}",
      path: Helpers.team_path(conn, :new)}
  end

  def team_login_url(conn, team) do
    URI.to_string %{build_uri_from_conn(conn) |
      host: "#{team.slug}.#{default_host()}",
      path: Helpers.session_path(conn, :new)}
  end

  def team_search_url(conn) do
    URI.to_string %{build_uri_from_conn(conn) |
      host: "launch.#{default_host()}",
      path: Helpers.team_search_path(conn, :new)}
  end

  def threads_url(conn, team) do
    URI.to_string %{build_uri_from_conn(conn) |
      host: "#{team.slug}.#{default_host()}",
      path: Helpers.thread_path(conn, :index)}
  end

  def build_url_with_subdomain(subdomain, path, config \\ nil) do
    config = config || default_url_config()

    host = Keyword.get(config, :host)
    scheme = Keyword.get(config, :scheme, "http")
    port = Keyword.get(config, :port)

    host = case subdomain do
      nil -> host
      val -> "#{val}.#{host}"
    end

    uri = %URI{
      scheme: scheme,
      host: host,
      path: path
    }

    uri = case port do
      nil -> uri
      80 -> uri
      443 -> uri
      port -> %{uri | port: port}
    end

    URI.to_string(uri)
  end

  def default_host do
    Keyword.get(default_url_config(), :host)
  end

  defp default_url_config do
    Application.get_env(:bridge, Endpoint)[:url]
  end

  defp build_uri_from_conn(conn) do
    %URI{
      scheme: Atom.to_string(conn.scheme),
      port: conn.port,
    }
  end
end
