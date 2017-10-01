defmodule LevelWeb.UrlHelpers do
  @moduledoc """
  A collection of URL helpers to assist with routing across subdomains.
  """

  alias LevelWeb.Router.Helpers
  alias LevelWeb.Endpoint

  def signup_url(conn) do
    URI.to_string %{build_uri_from_conn(conn) |
      host: "launch.#{default_host()}",
      path: Helpers.space_path(conn, :new)}
  end

  def space_login_url(conn, space) do
    URI.to_string %{build_uri_from_conn(conn) |
      host: "#{space.slug}.#{default_host()}",
      path: Helpers.session_path(conn, :new)}
  end

  def space_search_url(conn) do
    URI.to_string %{build_uri_from_conn(conn) |
      host: "launch.#{default_host()}",
      path: Helpers.space_search_path(conn, :new)}
  end

  def threads_url(conn, space) do
    URI.to_string %{build_uri_from_conn(conn) |
      host: "#{space.slug}.#{default_host()}",
      path: Helpers.thread_path(conn, :index)}
  end

  def build_url_with_subdomain(subdomain, path, config \\ nil) do
    config = config || default_url_config()

    base_host = Keyword.get(config, :host)
    scheme = Keyword.get(config, :scheme, "http")
    port = Keyword.get(config, :port)

    host = case subdomain do
      nil -> base_host
      val -> "#{val}.#{base_host}"
    end

    base_uri = %URI{
      scheme: scheme,
      host: host,
      path: path
    }

    uri = case port do
      nil -> base_uri
      80 -> base_uri
      443 -> base_uri
      port -> %{base_uri | port: port}
    end

    URI.to_string(uri)
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
      port: conn.port,
    }
  end
end
