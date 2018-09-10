use Mix.Config

config :level, mailer_host: "level.test"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :level, LevelWeb.Endpoint,
  http: [port: 4001],
  url: [host: "level.test", port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Switch to this configuration for verbose logging in tests
# config :logger,
#   backends: [:console],
#   compile_time_purge_level: :debug

# Configure your database
config :level, Level.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "level_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Make tests run faster by reducing encryption rounds
config :comeonin, :bcrypt_log_rounds, 4
config :comeonin, :pbkdf2_rounds, 1

# Configure the mailer
config :level, Level.Mailer, adapter: Bamboo.TestAdapter

# Configure asset storage
config :level, :asset_store, bucket: System.get_env("LEVEL_ASSET_STORE_BUCKET")

# Web push
config :level, Level.WebPush, adapter: Level.WebPush.TestAdapter

# Configure web push notifications
config :web_push_encryption, :vapid_details,
  subject: "https://level.app",
  public_key: System.get_env("LEVEL_WEB_PUSH_PUBLIC_KEY"),
  private_key: System.get_env("LEVEL_WEB_PUSH_PRIVATE_KEY")
