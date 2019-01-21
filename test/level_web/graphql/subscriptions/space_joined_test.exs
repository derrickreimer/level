defmodule LevelWeb.GraphQL.SpaceJoinedTest do
  use LevelWeb.ChannelCase

  @operation """
    subscription UserSubscription {
      userSubscription {
        __typename
        ... on SpaceJoinedPayload {
          space {
            id
            name
          }
          spaceUser {
            userId
          }
        }
      }
    }
  """

  setup do
    {:ok, user} = create_user()
    {:ok, %{socket: build_socket(user), user: user}}
  end

  test "receives an event when a user creates a space", %{socket: socket, user: user} do
    ref = push_subscription(socket, @operation, %{})
    assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

    {:ok, %{space: space}} = create_space(user, %{name: "MySpace"})

    push_data = %{
      result: %{
        data: %{
          "userSubscription" => %{
            "__typename" => "SpaceJoinedPayload",
            "space" => %{
              "id" => space.id,
              "name" => "MySpace"
            },
            "spaceUser" => %{
              "userId" => user.id
            }
          }
        }
      },
      subscriptionId: subscription_id
    }

    assert_push("subscription:data", ^push_data)
  end
end
