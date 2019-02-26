defmodule LevelWeb.GraphQL.GroupCreatedTest do
  use LevelWeb.ChannelCase

  @operation """
    subscription SpaceUserSubscription(
      $id: ID!
    ) {
      spaceUserSubscription(spaceUserId: $id) {
        __typename
        ... on GroupCreatedPayload {
          group {
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

  test "receives an event when a group is created that the user can access", %{
    socket: socket,
    space_user: space_user
  } do
    ref = push_subscription(socket, @operation, %{"id" => space_user.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, %{group: group}} = create_group(space_user)

    push_data = %{
      result: %{
        data: %{
          "spaceUserSubscription" => %{
            "__typename" => "GroupCreatedPayload",
            "group" => %{
              "id" => group.id
            }
          }
        }
      },
      subscriptionId: subscription_id
    }

    assert_push("subscription:data", ^push_data)
  end

  test "does not receive an event when a group is created that the user cannot access", %{
    socket: socket,
    space: space,
    space_user: space_user
  } do
    {:ok, %{space_user: another_user}} = create_space_member(space)

    ref = push_subscription(socket, @operation, %{"id" => space_user.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, %{group: group}} = create_group(another_user, %{is_private: true})

    push_data = %{
      result: %{
        data: %{
          "spaceUserSubscription" => %{
            "__typename" => "GroupCreatedPayload",
            "group" => %{
              "id" => group.id
            }
          }
        }
      },
      subscriptionId: subscription_id
    }

    refute_push("subscription:data", ^push_data)
  end
end
