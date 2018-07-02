defmodule LevelWeb.GraphQL.GroupUnbookmarkedTest do
  use LevelWeb.ChannelCase

  alias Level.Groups

  @operation """
    subscription SpaceUserSubscription(
      $id: ID!
    ) {
      spaceUserSubscription(spaceUserId: $id) {
        __typename
        ... on GroupUnbookmarkedPayload {
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

  test "receives an event when a group is unbookmarked", %{socket: socket, space_user: space_user} do
    {:ok, %{group: group, bookmarked: true}} =
      Groups.create_group(space_user, valid_group_params())

    ref = push_subscription(socket, @operation, %{"id" => space_user.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    Groups.unbookmark_group(group, space_user)

    assert_push("subscription:data", push_data)

    assert push_data == %{
             result: %{
               data: %{
                 "spaceUserSubscription" => %{
                   "__typename" => "GroupUnbookmarkedPayload",
                   "group" => %{
                     "id" => group.id
                   }
                 }
               }
             },
             subscriptionId: subscription_id
           }
  end

  test "rejects subscription if user is not authenticated", %{socket: socket, space: space} do
    {:ok, %{space_user: another_space_user}} = create_space_member(space)
    ref = push_subscription(socket, @operation, %{"id" => another_space_user.id})

    assert_reply(
      ref,
      :error,
      %{
        errors: [
          %{
            locations: [%{column: 0, line: 4}],
            message: "Subscription not authorized"
          }
        ]
      },
      1000
    )
  end
end
