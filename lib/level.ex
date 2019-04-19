defmodule Level do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    children = [
      Level.Repo,
      LevelWeb.Endpoint,
      LevelWeb.Presence,
      %{
        id: Absinthe.Subscription,
        start: {Absinthe.Subscription, :start_link, [LevelWeb.Endpoint]}
      },
      {Registry, keys: :unique, name: Level.Registry},
      Level.WebPush,
      Level.Scheduler
    ]

    opts = [strategy: :one_for_one, name: Level.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
