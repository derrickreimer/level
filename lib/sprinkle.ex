defmodule Sprinkle do
  @moduledoc false

  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Sprinkle.Repo, []),
      # Start the endpoint when the application starts
      supervisor(SprinkleWeb.Endpoint, []),
      # Start your own worker by calling: Sprinkle.Worker.start_link(arg1, arg2, arg3)
      # worker(Sprinkle.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sprinkle.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
