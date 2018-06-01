defmodule Level.FeatureFlags do
  def signups_enabled?(:prod), do: false
  def signups_enabled?(_), do: true
end
