defmodule Level.Mixfile do
  use Mix.Project

  @elixir_version "~> 1.7"
  @version "0.0.1"

  def project do
    [
      app: :level,
      version: @version,
      elixir: @elixir_version,
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: true,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      name: "Level",
      dialyzer: [
        flags: [:unmatched_returns, :error_handling, :race_conditions, :underspecs],
        ignore_warnings: "dialyzer.ignore-warnings"
      ],
      source_url: "https://github.com/levelhq/level",
      docs: docs()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Level, []}, extra_applications: [:logger, :runtime_tools, :honeybadger]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.13"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_markdown, "~> 1.0"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:plug_cowboy, "~> 1.0"},
      {:credo, "~> 0.9", only: [:dev, :test]},
      {:comeonin, "~> 3.0"},
      {:timex, "~> 3.0"},
      {:ex_doc, "~> 0.19"},
      {:absinthe, "~> 1.4.5"},
      {:absinthe_plug, "~> 1.4.0"},
      {:absinthe_phoenix, "~> 1.4.0"},
      {:dataloader, "~> 1.0.0"},
      {:joken, "~> 1.5"},
      {:bamboo, "~> 1.1"},
      {:bamboo_postmark, "~> 0.4.2"},
      {:excoveralls, "~> 0.8", only: :test},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:earmark, "~> 1.2.5"},
      {:html_sanitize_ex, "~> 1.3.0"},
      {:number, "~> 0.5.7"},
      {:floki, "~> 0.20.3"},
      {:web_push_encryption, "~> 0.2.1"},
      {:mox, "~> 0.4.0", only: :test},
      {:honeybadger, "~> 0.1"},
      {:quantum, "~> 2.3"},
      {:premailex, "~> 0.3.3"},

      # Amazon S3 dependencies
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.migrate": ["ecto.migrate"],
      "ecto.rollback": ["ecto.rollback"],
      test: ["ecto.create --quiet", "ecto.migrate", "run priv/repo/seeds.exs", "test"]
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      logo: "avatar.png"
    ]
  end
end
