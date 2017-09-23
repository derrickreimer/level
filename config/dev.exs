use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :sprinkle, SprinkleWeb.Endpoint,
  http: [port: 4000],
  url: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                    cd: Path.expand("../assets", __DIR__)]]


# Watch static and templates for browser reloading.
config :sprinkle, SprinkleWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/sprinkle/web/views/.*(ex)$},
      ~r{lib/sprinkle/web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :sprinkle, Sprinkle.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("SPRINKLE_DB_USERNAME") || "postgres",
  password: System.get_env("SPRINKLE_DB_PASSWORD") || "postgres",
  database: "sprinkle_dev",
  hostname: "localhost",
  pool_size: 10

# Mailer
config :sprinkle, Sprinkle.Mailer,
  adapter: Bamboo.LocalAdapter
