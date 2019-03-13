defmodule LevelWeb.GraphQL.NotificationDismissedTest do
  use LevelWeb.ChannelCase

  alias Level.Notifications
  alias Level.Schemas.Post

  @operation """
    subscription UserSubscription {
      userSubscription {
        __typename
        ... on NotificationDismissedPayload {
          notification {
            ... on PostCreatedNotification {
              id
            }
          }
        }
      }
    }
  """

  setup do
    {:ok, result} = create_user_and_space()
    {:ok, Map.put(result, :socket, build_socket(result.user))}
  end

  test "receives an event when a notification is dismissed", %{
    socket: socket,
    user: user,
    space_user: space_user
  } do
    post = %Post{id: "abc"}
    {:ok, notification} = Notifications.record_post_created(space_user, post)

    ref = push_subscription(socket, @operation, %{})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, _} = Notifications.dismiss_notification(user, notification)

    push_data = %{
      result: %{
        data: %{
          "userSubscription" => %{
            "__typename" => "NotificationDismissedPayload",
            "notification" => %{
              "id" => notification.id
            }
          }
        }
      },
      subscriptionId: subscription_id
    }

    assert_push("subscription:data", ^push_data)
  end
end
