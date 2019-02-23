defmodule LevelWeb.GraphQL.PostReactionCreatedTest do
  use LevelWeb.ChannelCase

  alias Level.Posts

  @operation """
    subscription SpaceUserSubscription(
      $id: ID!
    ) {
      spaceUserSubscription(spaceUserId: $id) {
        __typename
        ... on PostReactionCreatedPayload {
          post {
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

  test "receives an event when a user reacts to a post", %{socket: socket, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    ref = push_subscription(socket, @operation, %{"id" => space_user.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, _} = Posts.create_post_reaction(space_user, post)

    payload = %{
      result: %{
        data: %{
          "spaceUserSubscription" => %{
            "__typename" => "PostReactionCreatedPayload",
            "post" => %{
              "id" => post.id
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
