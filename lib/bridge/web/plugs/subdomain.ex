defmodule Bridge.Web.Subdomain do
  @moduledoc """
  Provides a plug for verifying the host and extracting the subdomain.
  """

  import Plug.Conn

  @doc """
  A plug that ensures that:

  - The host matches the configured hostname, and
  - The host is not `localhost` (because subdomains are required for routing).
  """
  def validate_host(conn, _opts \\ []) do
    cond do
      conn.host == "localhost" ->
        raise """
        Serving Bridge over localhost is not supported.

        Bridge relies on subdomains for routing. Configure your hosts accordingly.
        See https://github.com/djreimer/bridge#routing for more information.
        """

      String.ends_with?(conn.host, root_domain()) ->
        conn

      true ->
        raise """
        Bridge must be served from the hostname configured in your config/{env}.exs file.

        Your configured host is #{root_domain()}, but this request came via #{conn.host}.

        This is required to ensure cookie-setting and subdomain routing functions properly.
        See https://github.com/djreimer/bridge#routing for more information.
        """
    end
  end

  @doc """
  A plug that parses out the subdomain and sets it in the connection assigns.
  """
  def extract_subdomain(conn, _opts \\ []) do
    subdomain = conn.host
      |> String.trim_trailing(root_domain())
      |> String.trim_trailing(".")

    assign(conn, :subdomain, subdomain)
  end

  defp root_domain do
    Application.get_env(:bridge, Bridge.Web.Endpoint)[:url][:host]
  end
end
