defmodule LevelWeb.GraphQL.GroupUpdatedTest do
  use LevelWeb.ChannelCase

  alias Level.Groups

  @operation """
    subscription GroupSubscription(
      $id: ID!
    ) {
      groupSubscription(groupId: $id) {
        __typename
        ... on GroupUpdatedPayload {
          group {
            id
            name
          }
        }
      }
    }
  """

  setup do
    {:ok, result} = create_user_and_space()
    {:ok, Map.put(result, :socket, build_socket(result.user))}
  end

  test "receives an event when a group is updated", %{socket: socket, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)

    ref = push_subscription(socket, @operation, %{"id" => group.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, group} = Groups.update_group(group, %{name: "new-name"})

    push_data = %{
      result: %{
        data: %{
          "groupSubscription" => %{
            "__typename" => "GroupUpdatedPayload",
            "group" => %{
              "id" => group.id,
              "name" => "new-name"
            }
          }
        }
      },
      subscriptionId: subscription_id
    }

    assert_push("subscription:data", ^push_data)
  end
end
