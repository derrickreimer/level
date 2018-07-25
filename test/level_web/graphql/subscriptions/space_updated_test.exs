defmodule LevelWeb.GraphQL.SpaceUpdatedTest do
  use LevelWeb.ChannelCase

  alias Level.Spaces

  @operation """
    subscription SpaceSubscription(
      $id: ID!
    ) {
      spaceSubscription(spaceId: $id) {
        __typename
        ... on SpaceUpdatedPayload {
          space {
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

  test "receives an event when a space user is updated", %{socket: socket, space: space} do
    ref = push_subscription(socket, @operation, %{"id" => space.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, _} = Spaces.update_space(space, %{name: "New name"})

    assert_push("subscription:data", push_data)

    assert push_data == %{
             result: %{
               data: %{
                 "spaceSubscription" => %{
                   "__typename" => "SpaceUpdatedPayload",
                   "space" => %{
                     "id" => space.id,
                     "name" => "New name"
                   }
                 }
               }
             },
             subscriptionId: subscription_id
           }
  end

  test "rejects subscription if user is not authenticated", %{socket: socket} do
    {:ok, %{space: another_space}} = create_user_and_space()
    ref = push_subscription(socket, @operation, %{"id" => another_space.id})

    assert_reply(
      ref,
      :error,
      %{
        errors: [
          %{
            locations: [%{column: 0, line: 4}],
            message: "Space not found"
          }
        ]
      },
      1000
    )
  end
end
