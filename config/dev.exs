use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :level, LevelWeb.Endpoint,
  http: [port: 4000],
  url: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                    cd: Path.expand("../assets", __DIR__)]]


# Watch static and templates for browser reloading.
config :level, LevelWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/level/web/views/.*(ex)$},
      ~r{lib/level/web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :level, Level.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("LEVEL_DB_USERNAME") || "postgres",
  password: System.get_env("LEVEL_DB_PASSWORD") || "postgres",
  database: "level_dev",
  hostname: "localhost",
  pool_size: 10

# Mailer
config :level, Level.Mailer,
  adapter: Bamboo.LocalAdapter
