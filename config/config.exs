# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :level,
  ecto_repos: [Level.Repo],
  mailer_host: System.get_env("LEVEL_MAILER_HOST") || "level.test",
  env: Mix.env()

# Configures the endpoint
config :level, LevelWeb.Endpoint,
  secret_key_base: "88kKPFnN/WU+4j79qm1tucW43qkoNjH0Ju54I8X2+BpKzMqYbiq4yVwXuhf7HDzr",
  render_errors: [view: LevelWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Level.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure migrations to use UUIDs
config :level, :generators,
  migration: true,
  binary_id: true,
  sample_binary_id: "11111111-1111-1111-1111-111111111111"

# Configure external services
config :level, :drip, account_id: System.get_env("DRIP_ACCOUNT_ID")
config :level, :fathom, site_id: System.get_env("FATHOM_SITE_ID")
config :level, :fullstory, org: System.get_env("FULLSTORY_ORG")
config :level, :heap_analytics, app_id: System.get_env("HEAP_ANALYTICS_APP_ID")
config :level, :helpscout, beacon_id: System.get_env("HELPSCOUT_BEACON_ID")
config :level, :honeybadger_js, api_key: System.get_env("HONEYBADGER_JS_API_KEY")

# Configure the scheduler
config :level, Level.Scheduler,
  jobs: [
    # Every 10 minutes
    {"*/10 * * * *", {Level.DailyDigest, :periodic_task, []}}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
