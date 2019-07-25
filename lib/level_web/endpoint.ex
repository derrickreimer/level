defmodule LevelWeb.Endpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :level
  use Absinthe.Phoenix.Endpoint

  socket "/socket", LevelWeb.UserSocket, websocket: [timeout: 45_000, check_origin: false]

  plug :canonical_host

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :level,
    gzip: true,
    only_matching:
      ~w(css fonts images js robots.txt service-worker.js favicon android apple mstile safari browserconfig.xml site.webmanifest),
    headers: [{"access-control-allow-origin", "*"}]

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_level_key",
    signing_salt: "Yx0Th4sC",
    domain: Application.get_env(:level, LevelWeb.Endpoint)[:url][:host],
    max_age: 31_557_600

  plug LevelWeb.Router

  defp canonical_host(conn, _opts) do
    case Application.get_env(:level, :canonical_host) do
      host when is_binary(host) ->
        opts = PlugCanonicalHost.init(canonical_host: host)
        PlugCanonicalHost.call(conn, opts)

      _ ->
        conn
    end
  end
end
