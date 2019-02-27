defmodule LevelWeb.GraphQL.NotificationCreatedTest do
  use LevelWeb.ChannelCase

  alias Level.Groups

  @operation """
    subscription SpaceUserSubscription(
      $id: ID!
    ) {
      spaceUserSubscription(spaceUserId: $id) {
        __typename
        ... on NotificationCreatedPayload {
          notification {
            __typename
            ... on PostCreatedNotification {
              state
              post {
                id
              }
            }
            ... on ReplyCreatedNotification {
              state
              post {
                id
              }
              reply {
                id
              }
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

  test "receives an event when a post is created", %{
    socket: socket,
    space: space,
    space_user: space_user
  } do
    {:ok, %{space_user: another_user}} = create_space_member(space)
    {:ok, %{group: group}} = create_group(space_user)

    Groups.watch(group, space_user)

    ref = push_subscription(socket, @operation, %{"id" => space_user.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, %{post: post}} = create_post(another_user, group)

    push_data = %{
      result: %{
        data: %{
          "spaceUserSubscription" => %{
            "__typename" => "NotificationCreatedPayload",
            "notification" => %{
              "__typename" => "PostCreatedNotification",
              "state" => "UNDISMISSED",
              "post" => %{
                "id" => post.id
              }
            }
          }
        }
      },
      subscriptionId: subscription_id
    }

    assert_push("subscription:data", ^push_data)
  end

  test "receives an event when a reply is created", %{
    socket: socket,
    space: space,
    space_user: space_user
  } do
    {:ok, %{space_user: another_user}} = create_space_member(space)
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    ref = push_subscription(socket, @operation, %{"id" => space_user.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, %{reply: reply}} = create_reply(another_user, post)

    push_data = %{
      result: %{
        data: %{
          "spaceUserSubscription" => %{
            "__typename" => "NotificationCreatedPayload",
            "notification" => %{
              "__typename" => "ReplyCreatedNotification",
              "state" => "UNDISMISSED",
              "post" => %{
                "id" => post.id
              },
              "reply" => %{
                "id" => reply.id
              }
            }
          }
        }
      },
      subscriptionId: subscription_id
    }

    assert_push("subscription:data", ^push_data)
  end
end
