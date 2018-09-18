defmodule LevelWeb.GraphQL.RepliesViewedTest do
  use LevelWeb.ChannelCase

  alias Level.Posts

  @operation """
    subscription SpaceUserSubscription(
      $id: ID!
    ) {
      spaceUserSubscription(spaceUserId: $id) {
        __typename
        ... on RepliesViewedPayload {
          replies {
            id
            hasViewed
          }
        }
      }
    }
  """

  setup do
    {:ok, result} = create_user_and_space()
    {:ok, Map.put(result, :socket, build_socket(result.user))}
  end

  test "receives an event when a user views replies", %{
    socket: socket,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    {:ok, %{space_user: another_user}} = create_space_member(space)
    {:ok, %{reply: reply}} = create_reply(another_user, post)

    ref = push_subscription(socket, @operation, %{"id" => space_user.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    Posts.record_reply_views(space_user, [reply])

    push_data = %{
      result: %{
        data: %{
          "spaceUserSubscription" => %{
            "__typename" => "RepliesViewedPayload",
            "replies" => [
              %{
                "id" => reply.id,
                "hasViewed" => true
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
