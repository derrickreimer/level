defmodule LevelWeb.GraphQL.UpdateRoomTest do
  use LevelWeb.ConnCase
  import LevelWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)
    {:ok, %{room: room}} = insert_room(user)

    query = """
      mutation UpdateRoom(
        $id: ID!,
        $name: String,
        $description: String,
        $subscriberPolicy: RoomSubscriberPolicy
      ) {
        updateRoom(
          id: $id,
          name: $name,
          description: $description,
          subscriberPolicy: $subscriberPolicy
        ) {
          room {
            name
            description
            subscriberPolicy
          }
          success
          errors {
            attribute
            message
          }
        }
      }
    """

    {:ok, %{conn: conn, user: user, space: space, room: room, query: query}}
  end

  test "updates a room with valid data", %{conn: conn, room: room, query: query} do
    variables = %{
      id: to_string(room.id),
      name: "New Year, New Name",
      description: "Here goes the description",
      subscriberPolicy: "INVITE_ONLY"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "updateRoom" => %{
                 "success" => true,
                 "room" => %{
                   "name" => variables.name,
                   "description" => variables.description,
                   "subscriberPolicy" => variables.subscriberPolicy
                 },
                 "errors" => []
               }
             }
           }
  end

  test "returns validation errors when data is invalid", %{conn: conn, room: room, query: query} do
    variables = %{
      id: to_string(room.id),
      name: ""
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "updateRoom" => %{
                 "success" => false,
                 "room" => %{
                   "name" => room.name,
                   "description" => room.description,
                   "subscriberPolicy" => room.subscriber_policy
                 },
                 "errors" => [
                   %{"attribute" => "name", "message" => "can't be blank"}
                 ]
               }
             }
           }
  end
end
