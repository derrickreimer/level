defmodule LevelWeb.GraphQL.PostCreatedTest do
  use LevelWeb.ChannelCase

  alias Level.Posts

  @operation """
    subscription PostCreated(
      $id: ID!
    ) {
      postCreated(groupId: $id) {
        post {
          id
        }
      }
    }
  """

  setup do
    {:ok, result} = create_user_and_space()
    {:ok, Map.put(result, :socket, build_socket(result.user))}
  end

  test "receives an event a user posts to a group", %{socket: socket, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)

    ref = push_subscription(socket, @operation, %{"id" => group.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, %{post: post}} = Posts.post_to_group(space_user, group, valid_post_params())
    assert_push("subscription:data", push_data)

    assert push_data == %{
             result: %{
               data: %{
                 "postCreated" => %{
                   "post" => %{
                     "id" => post.id
                   }
                 }
               }
             },
             subscriptionId: subscription_id
           }
  end
end
