defmodule Level.Analytics.LogAdapter do
  @moduledoc false

  require Logger

  @behaviour Level.Analytics.Adapter

  @impl Level.Analytics.Adapter
  def identify(email, properties) do
    Logger.info("identify email=#{email}")
  end

  @impl Level.Analytics.Adapter
  def track(email, action, properties) do
    Logger.info("track email=#{email} action=#{action}")
  end
end
