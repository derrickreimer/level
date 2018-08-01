defmodule LevelWeb.GraphQL.ReplyCreatedTest do
  use LevelWeb.ChannelCase

  alias Level.Posts

  @operation """
    subscription PostSubscription(
      $id: ID!
    ) {
      postSubscription(postId: $id) {
        __typename
        ... on ReplyCreatedPayload {
          reply {
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

  test "receives an event when a user posts to a reply", %{socket: socket, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = Posts.create_post(space_user, group, valid_post_params())

    ref = push_subscription(socket, @operation, %{"id" => post.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, %{reply: reply}} = create_reply(space_user, post)
    assert_push("subscription:data", push_data)

    assert push_data == %{
             result: %{
               data: %{
                 "postSubscription" => %{
                   "__typename" => "ReplyCreatedPayload",
                   "reply" => %{
                     "id" => reply.id
                   }
                 }
               }
             },
             subscriptionId: subscription_id
           }
  end
end
