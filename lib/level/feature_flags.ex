defmodule Level.FeatureFlags do
  @moduledoc """
  Feature flags.
  """

  def signups_enabled?(config, key) do
    config[:enabled] || key == config[:key]
  end
end
