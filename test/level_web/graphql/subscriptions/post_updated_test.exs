defmodule LevelWeb.GraphQL.PostUpdatedTest do
  use LevelWeb.ChannelCase

  alias Level.Posts

  @operation """
    subscription PostSubscription(
      $id: ID!
    ) {
      postSubscription(postId: $id) {
        __typename
        ... on PostUpdatedPayload {
          post {
            id
            body
          }
        }
      }
    }
  """

  setup do
    {:ok, result} = create_user_and_space()
    {:ok, Map.put(result, :socket, build_socket(result.user))}
  end

  test "receives an event when a user updates a post", %{socket: socket, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    ref = push_subscription(socket, @operation, %{"id" => post.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, _} = Posts.update_post(space_user, post, %{body: "New body"})

    payload = %{
      result: %{
        data: %{
          "postSubscription" => %{
            "__typename" => "PostUpdatedPayload",
            "post" => %{
              "id" => post.id,
              "body" => "New body"
            }
          }
        }
      },
      subscriptionId: subscription_id
    }

    assert_push("subscription:data", ^payload)
  end
end
