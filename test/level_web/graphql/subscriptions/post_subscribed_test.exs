defmodule LevelWeb.GraphQL.PostSubscribedTest do
  use LevelWeb.ChannelCase

  alias Level.Posts

  @operation """
    subscription SpaceUserSubscription(
      $id: ID!
    ) {
      spaceUserSubscription(spaceUserId: $id) {
        __typename
        ... on PostSubscribedPayload {
          post {
            subscriptionState
          }
        }
      }
    }
  """

  setup do
    {:ok, result} = create_user_and_space()
    {:ok, Map.put(result, :socket, build_socket(result.user))}
  end

  test "receives an event when a user subscribes to a post", %{
    socket: socket,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = Posts.create_post(space_user, group, valid_post_params())
    :ok = Posts.unsubscribe(post, space_user)

    ref = push_subscription(socket, @operation, %{"id" => space_user.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    :ok = Posts.subscribe(post, space_user)

    push_data = %{
      result: %{
        data: %{
          "spaceUserSubscription" => %{
            "__typename" => "PostSubscribedPayload",
            "post" => %{
              "subscriptionState" => "SUBSCRIBED"
            }
          }
        }
      },
      subscriptionId: subscription_id
    }

    assert_push("subscription:data", ^push_data)
  end
end
