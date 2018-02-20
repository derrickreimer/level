defmodule LevelWeb.GraphQL.RoomMessageCreatedTest do
  use LevelWeb.ChannelCase
  alias LevelWeb.Schema

  @operation """
    subscription RoomMessageCreated(
      $userId: ID!
    ) {
      roomMessageCreated(userId: $userId) {
        roomMessage {
          body
        }
      }
    }
  """

  setup do
    {:ok, %{user: user, space: space}} = insert_signup()

    # Build the socket connection
    # A dummy value to demonstrate that it doesn't matter
    {:ok, _, socket} =
      "asdf"
      |> socket(absinthe: %{schema: Schema, opts: [context: %{current_user: user}]})
      |> subscribe_and_join(Absinthe.Phoenix.Channel, "__absinthe__:control")

    {:ok, %{socket: socket, user: user, space: space}}
  end

  test "receives an event when user posts to a room", %{socket: socket, user: user} do
    # Create a room that we'll be posting a message to
    {:ok, %{room: room}} = Level.Rooms.create_room(user, valid_room_params())

    # Register the subscription
    ref =
      push(socket, "doc", %{
        "query" => @operation,
        "variables" => %{"userId" => to_string(user.id)}
      })

    assert_reply(ref, :ok, %{subscriptionId: subscription_ref}, 1000)

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

    ref =
      push(socket, "doc", %{
        "query" => mutation,
        "variables" => variables
      })

    assert_reply(ref, :ok, reply)

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
    assert_push("subscription:data", push_data)

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

  test "rejects subscription if user not authenticated", %{socket: socket, space: space} do
    # Insert another member
    {:ok, another_user} = insert_member(space, valid_user_params())

    # Register the subscription
    ref =
      push(socket, "doc", %{
        "query" => @operation,
        "variables" => %{"userId" => to_string(another_user.id)}
      })

    assert_reply(
      ref,
      :error,
      %{
        errors: [
          %{
            locations: [%{column: 0, line: 4}],
            message: "User is not authenticated"
          }
        ]
      },
      1000
    )
  end
end
