defmodule Level.WebPushTest do
  use Level.DataCase, async: true

  alias Level.WebPush
  alias Level.WebPush.Subscription

  @valid_data """
    {
      "endpoint": "https://endpoint.test",
      "expirationTime": null,
      "keys": {
        "p256dh": "p256dh",
        "auth": "auth"
      }
    }
  """

  describe "parse_subscription/1" do
    test "parses valid data" do
      {:ok, %Subscription{} = subscription} = WebPush.parse_subscription(@valid_data)
      assert subscription.endpoint == "https://endpoint.test"
      assert subscription.keys.auth == "auth"
      assert subscription.keys.p256dh == "p256dh"
    end

    test "errors out if keys are not valid" do
      assert {:error, :invalid_keys} = WebPush.parse_subscription(~s({"foo": "bar"}))
    end

    test "errors out if JSON is invalid" do
      assert {:error, :parse_error} = WebPush.parse_subscription(~s({"foo"))
    end
  end
end
