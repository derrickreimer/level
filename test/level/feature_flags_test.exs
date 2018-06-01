defmodule Level.FeatureFlagsTest do
  use Level.DataCase, async: true

  alias Level.FeatureFlags

  describe "signups_enabled?/1" do
    test "is true in non-prod environments" do
      assert FeatureFlags.signups_enabled?(:test)
      assert FeatureFlags.signups_enabled?(:dev)
    end

    test "is false in prod" do
      refute FeatureFlags.signups_enabled?(:prod)
    end
  end
end
