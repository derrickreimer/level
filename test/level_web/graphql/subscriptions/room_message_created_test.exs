defmodule LevelWeb.GraphQL.RoomMessageCreatedTest do
  use LevelWeb.ChannelCase
  alias LevelWeb.Schema

  setup do
    {:ok, %{user: user, space: space}} = insert_signup()

    # Build the socket connection
    {:ok, _, socket} =
      "asdf" # A dummy value to demonstrate that it doesn't matter
      |> socket(absinthe: %{schema: Schema, opts: [context: %{current_user: user}]})
      |> subscribe_and_join(Absinthe.Phoenix.Channel, "__absinthe__:control")

    {:ok, %{socket: socket, user: user, space: space}}
  end

  test "receives an event when user posts to a room",
    %{socket: socket, user: user} do

    # Create a room that we'll be posting a message to
    {:ok, %{room: room}} = Level.Rooms.create_room(user, valid_room_params())

    # Register the subscription
    subscription = """
      subscription RoomMessageCreated(
        $roomId: ID!
      ) {
        roomMessageCreated(roomId: $roomId) {
          roomMessage {
            body
          }
        }
      }
    """

    ref = push socket, "doc", %{
      "query" => subscription,
      "variables" => %{"roomId" => to_string(room.id)}
    }
    assert_reply ref, :ok, %{subscriptionId: subscription_ref}, 1000

    # Push up a mutation
    mutation = """
      mutation CreateRoomMessage(
        $roomId: ID!
        $body: String!
      ) {
        createRoomMessage(
          roomId: $roomId,
          body: $body
        ) {
          roomMessage {
            body
          }
          success
          errors {
            attribute
            message
          }
        }
      }
    """

    variables = %{
      roomId: room.id,
      body: "Hello world"
    }

    ref = push socket, "doc", %{
      "query" => mutation,
      "variables" => variables
    }

    assert_reply ref, :ok, reply

    mutation_data = %{
      "createRoomMessage" => %{
        "success" => true,
        "roomMessage" => %{
          "body" => variables.body
        },
        "errors" => []
      }
    }

    assert reply == %{data: mutation_data}

    # Verify that a subscription push is made
    assert_push "subscription:data", push_data

    assert push_data == %{
      result: %{
        data: %{
          "roomMessageCreated" => %{
            "roomMessage" => %{
              "body" => variables.body
            }
          }
        }
      },
      subscriptionId: subscription_ref
    }
  end
end
