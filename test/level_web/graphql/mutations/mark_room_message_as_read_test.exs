defmodule LevelWeb.GraphQL.MarkRoomMessageAsReadTest do
  use LevelWeb.ConnCase
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Rooms

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)

    query = """
      mutation MarkRoomMessageAsRead(
        $roomId: ID!,
        $messageId: ID!
      ) {
        markRoomMessageAsRead(
          roomId: $roomId,
          messageId: $messageId
        ) {
          success
          roomSubscription {
            lastReadMessage {
              id
            }
          }
          errors {
            attribute
            message
          }
        }
      }
    """

    {:ok, %{room: room, room_subscription: room_subscription}} =
      Rooms.create_room(user, %{name: "Development"})

    {:ok,
     %{
       conn: conn,
       user: user,
       space: space,
       query: query,
       room: room,
       room_subscription: room_subscription
     }}
  end

  test "sets the last read message", %{
    conn: conn,
    query: query,
    room: room,
    room_subscription: room_subscription
  } do
    {:ok, %{room_message: message, room_subscription: room_subscription}} =
      Rooms.create_message(room_subscription, valid_room_message_params())

    # Forcibly ensure that there is not last read message set on the subscription
    room_subscription
    |> Ecto.Changeset.change(last_read_message_id: nil)
    |> Repo.update()

    variables = %{
      roomId: to_string(room.id),
      messageId: to_string(message.id)
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "markRoomMessageAsRead" => %{
                 "success" => true,
                 "roomSubscription" => %{
                   "lastReadMessage" => %{
                     "id" => to_string(message.id)
                   }
                 },
                 "errors" => []
               }
             }
           }

    mutated_subscription = Repo.get(Rooms.RoomSubscription, room_subscription.id)
    assert mutated_subscription.last_read_message_id == message.id
  end
end
