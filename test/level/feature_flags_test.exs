defmodule Level.FeatureFlagsTest do
  use Level.DataCase, async: true

  alias Level.FeatureFlags

  describe "signups_enabled?/2" do
    test "is true if enabled, regardless of key" do
      assert FeatureFlags.signups_enabled?(%{enabled: true, key: "foo"}, nil)
      assert FeatureFlags.signups_enabled?(%{enabled: true, key: "bar"}, "foo")
    end

    test "is false if not enabled and keys don't match" do
      refute FeatureFlags.signups_enabled?(%{enabled: false, key: "foo"}, nil)
      refute FeatureFlags.signups_enabled?(%{enabled: false, key: "foo"}, "bar")
      assert FeatureFlags.signups_enabled?(%{enabled: false, key: "foo"}, "foo")
    end
  end
end
