defmodule LevelWeb.GraphQL.SubscribedToGroupTest do
  use LevelWeb.ChannelCase

  alias Level.Groups

  @operation """
    subscription GroupSubscription(
      $id: ID!
    ) {
      groupSubscription(groupId: $id) {
        __typename
        ... on SubscribedToGroupPayload {
          spaceUser {
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

  test "receives an event when a user subscribes to a group", %{
    socket: socket,
    space: space,
    space_user: space_user
  } do
    {:ok, %{space_user: another_user}} = create_space_member(space)
    {:ok, %{group: group}} = create_group(another_user)

    ref = push_subscription(socket, @operation, %{"id" => group.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    :ok = Groups.subscribe(group, space_user)

    push_data = %{
      result: %{
        data: %{
          "groupSubscription" => %{
            "__typename" => "SubscribedToGroupPayload",
            "spaceUser" => %{
              "id" => space_user.id
            }
          }
        }
      },
      subscriptionId: subscription_id
    }

    assert_push("subscription:data", ^push_data)
  end

  test "rejects subscription if user cannot access the group", %{socket: socket, space: space} do
    {:ok, %{space_user: another_space_user}} = create_space_member(space)
    {:ok, %{group: group}} = create_group(another_space_user, %{is_private: true})

    ref = push_subscription(socket, @operation, %{"id" => group.id})

    assert_reply(
      ref,
      :error,
      %{
        errors: [
          %{
            locations: [%{column: 0, line: 4}],
            message: "Group not found"
          }
        ]
      },
      1000
    )
  end
end
