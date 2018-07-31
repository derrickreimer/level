defmodule LevelWeb.GraphQL.GroupMembershipUpdatedTest do
  use LevelWeb.ChannelCase

  alias Level.Groups
  alias Level.Groups.GroupUser

  @operation """
    subscription GroupSubscription(
      $id: ID!
    ) {
      groupSubscription(groupId: $id) {
        __typename
        ... on GroupMembershipUpdatedPayload {
          membership {
            state
            group {
              id
            }
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

  test "receives an event when a user leaves a group", %{socket: socket, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)

    ref = push_subscription(socket, @operation, %{"id" => group.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, %{group_user: nil}} =
      Groups.update_group_membership(group, space_user, "NOT_SUBSCRIBED")

    assert_push("subscription:data", push_data)

    assert push_data == %{
             result: %{
               data: %{
                 "groupSubscription" => %{
                   "__typename" => "GroupMembershipUpdatedPayload",
                   "membership" => nil
                 }
               }
             },
             subscriptionId: subscription_id
           }
  end

  test "receives an event when a user joins a group", %{socket: socket, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    Groups.update_group_membership(group, space_user, "NOT_SUBSCRIBED")

    ref = push_subscription(socket, @operation, %{"id" => group.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, %{group_user: %GroupUser{state: "SUBSCRIBED"}}} =
      Groups.update_group_membership(group, space_user, "SUBSCRIBED")

    assert_push("subscription:data", push_data)

    assert push_data == %{
             result: %{
               data: %{
                 "groupSubscription" => %{
                   "__typename" => "GroupMembershipUpdatedPayload",
                   "membership" => %{
                     "group" => %{
                       "id" => group.id
                     },
                     "spaceUser" => %{
                       "id" => space_user.id
                     },
                     "state" => "SUBSCRIBED"
                   }
                 }
               }
             },
             subscriptionId: subscription_id
           }
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
