defmodule Level.Mixfile do
  use Mix.Project

  @elixir_version "~> 1.6"
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
    [mod: {Level, []}, extra_applications: [:logger, :runtime_tools]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.2"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:credo, "~> 0.9", only: [:dev, :test]},
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
      {:excoveralls, "~> 0.8", only: :test},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:earmark, "~> 1.2.5"},
      {:html_sanitize_ex, "~> 1.3.0"},
      {:number, "~> 0.5.7"},

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
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      groups_for_modules: groups_for_modules(),
      logo: "avatar.png"
    ]
  end

  defp groups_for_modules do
    [
      Connections: [
        Level.Connections,
        Level.Connections.GroupPosts,
        Level.Connections.Groups,
        Level.Connections.GroupMemberships,
        Level.Connections.Invitations,
        Level.Connections.Replies,
        Level.Connections.SpaceUsers,
        Level.Connections.UserGroupMemberships,
        Level.Connections.Users
      ],
      Mutations: [
        Level.Mutations
      ],
      Pagination: [
        Level.Pagination,
        Level.Pagination.Args
      ],
      "Repo and Schemas": [
        Level.Repo,
        Level.Groups.Group,
        Level.Groups.GroupBookmark,
        Level.Groups.GroupMembership,
        Level.Groups.GroupUser,
        Level.Posts.Post,
        Level.Posts.PostGroup,
        Level.Posts.Reply,
        Level.Spaces.Invitation,
        Level.Spaces.OpenInvitation,
        Level.Spaces.Space,
        Level.Spaces.SpaceSetupStep,
        Level.Spaces.SpaceUser,
        Level.Users.Reservation,
        Level.Users.User
      ],
      Plugs: [
        LevelWeb.Absinthe,
        LevelWeb.Auth
      ],
      "Transactional Email": [
        Level.Mailer,
        LevelWeb.Email
      ],
      I18n: [
        Level.Gettext
      ],
      Helpers: [
        LevelWeb.ErrorHelpers,
        LevelWeb.FormHelpers,
        LevelWeb.ResolverHelpers,
        LevelWeb.Router.Helpers
      ]
    ]
  end
end
