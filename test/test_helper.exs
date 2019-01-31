ExUnit.configure(formatters: [ExUnit.CLIFormatter, TestmetricsElixirClient])
ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Level.Repo, :manual)
