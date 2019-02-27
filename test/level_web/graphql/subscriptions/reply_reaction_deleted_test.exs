defmodule LevelWeb.GraphQL.ReplyReactionDeletedTest do
  use LevelWeb.ChannelCase

  alias Level.Posts

  @operation """
    subscription SpaceUserSubscription(
      $id: ID!
    ) {
      spaceUserSubscription(spaceUserId: $id) {
        __typename
        ... on ReplyReactionDeletedPayload {
          reply {
            id
          }
          reaction {
            spaceUser {
              id
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

  test "receives an event when a user unreacts to a reply", %{
    socket: socket,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)
    {:ok, %{reply: reply}} = create_reply(space_user, post)
    {:ok, _} = Posts.create_reply_reaction(space_user, post, reply)

    ref = push_subscription(socket, @operation, %{"id" => space_user.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, _} = Posts.delete_reply_reaction(space_user, reply)

    payload = %{
      result: %{
        data: %{
          "spaceUserSubscription" => %{
            "__typename" => "ReplyReactionDeletedPayload",
            "reply" => %{
              "id" => reply.id
            },
            "reaction" => %{
              "spaceUser" => %{
                "id" => space_user.id
              }
            }
          }
        }
      },
      subscriptionId: subscription_id
    }

    assert_push("subscription:data", ^payload)
  end
end
