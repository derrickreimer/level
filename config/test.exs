use Mix.Config

config :sprinkle,
  mailer_host: "sprinkle.test"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sprinkle, SprinkleWeb.Endpoint,
  http: [port: 4001],
  url: [host: "sprinkle.test", port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Switch to this configuration for verbose logging in tests
# config :logger,
#   backends: [:console],
#   compile_time_purge_level: :debug

# Configure your database
config :sprinkle, Sprinkle.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "sprinkle_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Make tests run faster by reducing encryption rounds
config :comeonin, :bcrypt_log_rounds, 4
config :comeonin, :pbkdf2_rounds, 1

# Mailer
config :sprinkle, Sprinkle.Mailer,
  adapter: Bamboo.TestAdapter
