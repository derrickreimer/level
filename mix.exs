defmodule Level.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :level,
     version: @version,
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [coveralls: :test],
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps(),
     name: "Level",
     docs: docs()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Level, []},
     extra_applications: [:logger, :runtime_tools]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.3.0"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_ecto, "~> 3.2"},
     {:postgrex, ">= 0.0.0"},
     {:phoenix_html, "~> 2.6"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.11"},
     {:cowboy, "~> 1.0"},
     {:credo, "~> 0.7", only: [:dev, :test]},
     {:comeonin, "~> 3.0"},
     {:timex, "~> 3.0"},
     {:ex_doc, "~> 0.18.1"},
     {:absinthe, "~> 1.4.5"},
     {:absinthe_plug, "~> 1.4.0"},
     {:absinthe_phoenix, "~> 1.4.0"},
     {:dataloader, "~> 1.0.0"},
     {:joken, "~> 1.5"},
     {:bamboo, "~> 0.8"},
     {:bamboo_smtp, "~> 1.4"},
     {:excoveralls, "~> 0.7", only: :test}]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "ecto.migrate": ["ecto.migrate"],
     "ecto.rollback": ["ecto.rollback"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end

  defp docs do
    [
      source_url: "https://github.com/djreimer/level",
      extras: ["README.md"],
      groups_for_modules: groups_for_modules()
    ]
  end

  defp groups_for_modules do
    [
      "Contexts": [
        Level.Connections,
        Level.Mailer,
        Level.Pagination,
        Level.Rooms,
        Level.Spaces,
        Level.Threads
      ],
      "Repo and Schemas": [
        Level.Repo,
        Level.Rooms.Message,
        Level.Rooms.RoomSubscription,
        Level.Rooms.Room,
        Level.Spaces.Invitation,
        Level.Spaces.Space,
        Level.Spaces.User,
        Level.Threads.Draft
      ],
      "Plugs": [
        LevelWeb.Auth,
        LevelWeb.Subdomain
      ],
      "GraphQL Resolvers": [
        LevelWeb.DraftResolver,
        LevelWeb.InvitationResolver,
        LevelWeb.RoomMessageResolver,
        LevelWeb.RoomResolver,
        LevelWeb.SpaceResolver,
        LevelWeb.UserResolver
      ],
      "Transactional Email": [
        Level.Mailer,
        LevelWeb.Email
      ],
      "I18n": [
        Level.Gettext
      ],
      "Helpers": [
        LevelWeb.ErrorHelpers,
        LevelWeb.ResolverHelpers,
        LevelWeb.Router.Helpers,
        LevelWeb.UrlHelpers
      ]
    ]
  end
end
