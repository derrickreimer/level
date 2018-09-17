defmodule Level.WebPushTest do
  use Level.DataCase, async: true

  # import Mox

  alias Level.WebPush
  # alias Level.WebPush.Payload
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
  #   setup :verify_on_exit!

  #   test "assembles a notification body and passes it to the adapter", %{web_push: web_push} do
  #     {:ok, sub} = WebPush.parse_subscription(@valid_data)
  #     payload = %Payload{body: "foo", tag: "bar"}

  #     Level.WebPush.TestAdapter
  #     |> expect(:send_web_push, fn received_payload, received_sub ->
  #       assert received_payload == Payload.serialize(payload)
  #       assert received_sub == sub

  #       {:ok, %{status_code: 201}}
  #     end)

  #     assert :ok = WebPush.send_web_push(payload, sub)
  #   end
  # end
end
