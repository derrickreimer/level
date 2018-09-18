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

  # describe "send_web_push/2" do
  #   setup :set_mox_global
  #   setup :verify_on_exit!

  #   setup do
  #     {:ok, user} = create_user()
  #     {:ok, data} = WebPush.subscribe(user.id, @valid_data)
  #     {:ok, Map.merge(data, %{user: user})}
  #   end

  #   test "assembles a notification body and passes it to the adapter", %{
  #     user: user,
  #     subscription: subscription
  #   } do
  #     payload = %Payload{body: "Hello world"}

  #     Level.WebPush.TestAdapter
  #     |> expect(:send_web_push, fn body, sub ->
  #       assert body == Payload.serialize(payload)
  #       assert sub.endpoint == subscription.endpoint

  #       {:ok, %{status_code: 201}}
  #     end)

  #     assert :ok = WebPush.send_web_push(user.id, payload)
  #   end
  # end
end
