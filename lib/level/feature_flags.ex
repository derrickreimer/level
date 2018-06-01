defmodule Level.FeatureFlags do
  @moduledoc """
  Feature flags.
  """

  def signups_enabled?(:prod), do: false
  def signups_enabled?(_), do: true
end
