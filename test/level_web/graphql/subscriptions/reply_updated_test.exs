defmodule LevelWeb.GraphQL.ReplyUpdatedTest do
  use LevelWeb.ChannelCase

  alias Level.Posts

  @operation """
    subscription PostSubscription(
      $id: ID!
    ) {
      postSubscription(postId: $id) {
        __typename
        ... on ReplyUpdatedPayload {
          reply {
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
    {:ok, %{reply: reply}} = create_reply(space_user, post, %{body: "Old body"})

    ref = push_subscription(socket, @operation, %{"id" => post.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, _} = Posts.update_reply(space_user, reply, %{body: "New body"})

    payload = %{
      result: %{
        data: %{
          "postSubscription" => %{
            "__typename" => "ReplyUpdatedPayload",
            "reply" => %{
              "id" => reply.id,
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
