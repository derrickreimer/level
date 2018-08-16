defmodule LevelWeb.GraphQL.MentionsDismissedTest do
  use LevelWeb.ChannelCase

  alias Level.Mentions

  @operation """
    subscription SpaceUserSubscription(
      $id: ID!
    ) {
      spaceUserSubscription(spaceUserId: $id) {
        __typename
        ... on MentionsDismissedPayload {
          post {
            id
          }
        }
      }
    }
  """

  setup do
    {:ok, result} = create_user_and_space()
    {:ok, Map.put(result, :socket, build_socket(result.user))}
  end

  test "receives an event when a user dismisses mentions", %{
    socket: socket,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group, valid_post_params())

    ref = push_subscription(socket, @operation, %{"id" => space_user.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    :ok = Mentions.dismiss_all(space_user, post)

    payload = %{
      result: %{
        data: %{
          "spaceUserSubscription" => %{
            "__typename" => "MentionsDismissedPayload",
            "post" => %{
              "id" => post.id
            }
          }
        }
      },
      subscriptionId: subscription_id
    }

    assert_push("subscription:data", ^payload)
  end
end
