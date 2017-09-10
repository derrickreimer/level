use Mix.Config

config :neuron,
  mailer_host: "neuron.test"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :neuron, NeuronWeb.Endpoint,
  http: [port: 4001],
  url: [host: "neuron.test", port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Switch to this configuration for verbose logging in tests
# config :logger,
#   backends: [:console],
#   compile_time_purge_level: :debug

# Configure your database
config :neuron, Neuron.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "neuron_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Make tests run faster by reducing encryption rounds
config :comeonin, :bcrypt_log_rounds, 4
config :comeonin, :pbkdf2_rounds, 1

# Mailer
config :neuron, Neuron.Mailer,
  adapter: Bamboo.TestAdapter
