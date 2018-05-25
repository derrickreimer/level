defmodule Level.Groups.GroupUserTest do
  use Level.DataCase, async: true

  alias Level.Groups.GroupUser

  test "has a subscription level" do
    struct = %GroupUser{}
    assert struct.subscription_level == "SUBSCRIBED"
  end
end
