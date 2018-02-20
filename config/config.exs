# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :level,
  ecto_repos: [Level.Repo],
  mailer_host: System.get_env("LEVEL_MAILER_HOST") || "level.test"

# Configures the endpoint
config :level, LevelWeb.Endpoint,
  url: [host: System.get_env("LEVEL_HOST") || "level.test"],
  secret_key_base: "88kKPFnN/WU+4j79qm1tucW43qkoNjH0Ju54I8X2+BpKzMqYbiq4yVwXuhf7HDzr",
  render_errors: [view: LevelWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Level.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
