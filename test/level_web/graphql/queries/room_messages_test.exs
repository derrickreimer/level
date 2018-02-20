defmodule LevelWeb.GraphQL.RoomMessagesTest do
  use LevelWeb.ConnCase
  import LevelWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)

    {:ok, %{room: room, room_subscription: room_subscription}} =
      Level.Rooms.create_room(user, valid_room_params())

    {:ok, %{room_message: message}} =
      Level.Rooms.create_message(room_subscription, valid_room_message_params())

    {:ok, %{conn: conn, user: user, room: room, message: message}}
  end

  test "returns room messages", %{conn: conn, user: user, room: room, message: message} do
    query = """
      query GetRoomMessages(
        $id: ID!
      ) {
        viewer {
          room(id: $id) {
            messages(first: 10) {
              edges {
                node {
                  id
                  body
                  user {
                    firstName
                    lastName
                  }
                  insertedAtTs
                }
              }
              total_count
            }
          }
        }
      }
    """

    variables = %{
      id: to_string(room.id)
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "viewer" => %{
                 "room" => %{
                   "messages" => %{
                     "edges" => [
                       %{
                         "node" => %{
                           "id" => to_string(message.id),
                           "body" => message.body,
                           "user" => %{
                             "firstName" => user.first_name,
                             "lastName" => user.last_name
                           },
                           "insertedAtTs" =>
                             DateTime.to_unix(
                               Timex.to_datetime(message.inserted_at),
                               :millisecond
                             )
                         }
                       }
                     ],
                     "total_count" => 1
                   }
                 }
               }
             }
           }
  end
end
