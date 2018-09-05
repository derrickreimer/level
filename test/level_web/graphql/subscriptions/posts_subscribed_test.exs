defmodule LevelWeb.GraphQL.PostsSubscribedTest do
  use LevelWeb.ChannelCase

  alias Level.Posts

  @operation """
    subscription SpaceUserSubscription(
      $id: ID!
    ) {
      spaceUserSubscription(spaceUserId: $id) {
        __typename
        ... on PostsSubscribedPayload {
          posts {
            id
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
    Posts.unsubscribe(space_user, [post])

    ref = push_subscription(socket, @operation, %{"id" => space_user.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    Posts.subscribe(space_user, [post])

    push_data = %{
      result: %{
        data: %{
          "spaceUserSubscription" => %{
            "__typename" => "PostsSubscribedPayload",
            "posts" => [
              %{
                "id" => post.id,
                "subscriptionState" => "SUBSCRIBED"
              }
            ]
          }
        }
      },
      subscriptionId: subscription_id
    }

    assert_push("subscription:data", ^push_data)
  end
end
