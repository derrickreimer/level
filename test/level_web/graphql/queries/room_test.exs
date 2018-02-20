defmodule LevelWeb.GraphQL.RoomTest do
  use LevelWeb.ConnCase
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Rooms

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)
    {:ok, %{conn: conn, user: user, space: space}}
  end

  test "returns room if user is a member", %{conn: conn, user: user} do
    room_params =
      valid_room_params()
      |> Map.put(:subscriber_policy, "INVITE_ONLY")

    {:ok, %{room: room}} = Rooms.create_room(user, room_params)

    query = """
      query GetRoom(
        $id: ID!
      ) {
        viewer {
          room(id: $id) {
            id
            name
            description
            users(first: 1) {
              edges {
                node {
                  id
                }
              }
            }
            creator {
              id
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
                   "id" => to_string(room.id),
                   "name" => room.name,
                   "description" => room.description,
                   "creator" => %{
                     "id" => to_string(user.id)
                   },
                   "users" => %{
                     "edges" => [
                       %{
                         "node" => %{
                           "id" => to_string(user.id)
                         }
                       }
                     ]
                   }
                 }
               }
             }
           }
  end
end
