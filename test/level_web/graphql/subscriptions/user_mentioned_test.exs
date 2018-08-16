defmodule LevelWeb.GraphQL.UserMentionedTest do
  use LevelWeb.ChannelCase

  @operation """
    subscription SpaceUserSubscription(
      $id: ID!
    ) {
      spaceUserSubscription(spaceUserId: $id) {
        __typename
        ... on UserMentionedPayload {
          post {
            body
            mentions {
              mentioner {
                id
              }
            }
          }
        }
      }
    }
  """

  setup do
    {:ok, result} = create_user_and_space(%{handle: "derrick"})
    {:ok, Map.put(result, :socket, build_socket(result.user))}
  end

  test "receives an event when a user mentions another user", %{
    socket: socket,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{space_user: another_user}} = create_space_member(space)

    ref = push_subscription(socket, @operation, %{"id" => space_user.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, %{post: _post}} = create_post(another_user, group, %{body: "Hey @derrick"})

    push_data = %{
      result: %{
        data: %{
          "spaceUserSubscription" => %{
            "__typename" => "UserMentionedPayload",
            "post" => %{
              "body" => "Hey @derrick",
              "mentions" => [
                %{
                  "mentioner" => %{
                    "id" => another_user.id
                  }
                }
              ]
            }
          }
        }
      },
      subscriptionId: subscription_id
    }

    assert_push("subscription:data", ^push_data)
  end
end
