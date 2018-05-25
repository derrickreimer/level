defmodule Level.Groups.GroupUserTest do
  use Level.DataCase, async: true

  alias Level.Groups.GroupUser

  test "has a default state of subscribed" do
    struct = %GroupUser{}
    assert struct.state == "SUBSCRIBED"
  end
end
