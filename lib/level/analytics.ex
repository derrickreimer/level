defmodule Level.Analytics do
  @moduledoc """
  Tracking identity and events in external providers.
  """

  @adapter Application.get_env(:level, __MODULE__)[:adapter]

  def identify(email, properties \\ %{}) do
    Task.start(fn ->
      @adapter.identify(email, properties)
    end)
  end

  def track(email, action, properties \\ %{}) do
    Task.start(fn ->
      @adapter.track(email, action, properties)
    end)
  end
end
