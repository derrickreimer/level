defmodule LevelWeb.Subdomain do
  @moduledoc """
  Provides a plug for verifying the host and extracting the subdomain.
  """

  import Plug.Conn
  import LevelWeb.UrlHelpers

  @doc """
  A plug that ensures that:

  - The host matches the configured hostname, and
  - The host is not `localhost` (because subdomains are required for routing).
  """
  def validate_host(conn, _opts \\ []) do
    cond do
      conn.host == "localhost" ->
        raise """
        Serving Level over localhost is not supported.

        Level relies on subdomains for routing. Configure your hosts accordingly.
        See https://github.com/djreimer/level#routing for more information.
        """

      String.ends_with?(conn.host, default_host()) ->
        conn

      true ->
        raise """
        Level must be served from the hostname configured in your config/{env}.exs file.

        Your configured host is #{default_host()}, but this request came via #{conn.host}.

        This is required to ensure cookie-setting and subdomain routing functions properly.
        See https://github.com/djreimer/level#routing for more information.
        """
    end
  end

  @doc """
  A plug that parses out the subdomain and sets it in the connection assigns.
  """
  def extract_subdomain(conn, _opts \\ []) do
    subdomain = conn.host
      |> String.trim_trailing(default_host())
      |> String.trim_trailing(".")

    assign(conn, :subdomain, subdomain)
  end
end
