defmodule Level.Analytics do
  @moduledoc """
  Tracking identity and events in external providers.
  """

  @adapter Application.get_env(:level, __MODULE__)[:adapter]

  def identify(email, properties \\ %{}) do
    @adapter.identify(email, properties)
  end

  def track(email, action, properties \\ %{}) do
    @adapter.track(email, action, properties)
  end
end
