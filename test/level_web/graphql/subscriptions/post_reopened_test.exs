defmodule LevelWeb.GraphQL.PostReopenedTest do
  use LevelWeb.ChannelCase

  alias Level.Posts

  @operation """
    subscription PostSubscription(
      $id: ID!
    ) {
      postSubscription(postId: $id) {
        __typename
        ... on PostReopenedPayload {
          post {
            id
            state
          }
        }
      }
    }
  """

  setup do
    {:ok, result} = create_user_and_space()
    {:ok, Map.put(result, :socket, build_socket(result.user))}
  end

  test "receives an event when a user reopens a post", %{socket: socket, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    ref = push_subscription(socket, @operation, %{"id" => post.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, _} = Posts.reopen_post(space_user, post)

    payload = %{
      result: %{
        data: %{
          "postSubscription" => %{
            "__typename" => "PostReopenedPayload",
            "post" => %{
              "id" => post.id,
              "state" => "OPEN"
            }
          }
        }
      },
      subscriptionId: subscription_id
    }

    assert_push("subscription:data", ^payload)
  end
end
