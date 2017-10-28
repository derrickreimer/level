defmodule LevelWeb.GraphQL.CreateRoomMessageTest do
  use LevelWeb.ConnCase
  import LevelWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)

    query = """
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

    {:ok, %{room: room}} = Level.Rooms.create_room(user, valid_room_params())
    {:ok, %{conn: conn, user: user, space: space, query: query, room: room}}
  end

  test "creates a room with valid data",
    %{conn: conn, query: query, room: room} do

    variables = %{
      roomId: room.id,
      body: "Hello world"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
      "data" => %{
        "createRoomMessage" => %{
          "success" => true,
          "roomMessage" => %{
            "body" => variables.body
          },
          "errors" => []
        }
      }
    }
  end

  test "returns validation errors when data is invalid",
    %{conn: conn, query: query, room: room} do

      variables = %{
        roomId: room.id,
        body: "" # body is required
      }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
      "data" => %{
        "createRoomMessage" => %{
          "success" => false,
          "roomMessage" => nil,
          "errors" => [
            %{"attribute" => "body", "message" => "can't be blank"}
          ]
        }
      }
    }
  end

  test "errors out if room is not found",
    %{conn: conn, query: query} do

      variables = %{
        roomId: "999999",
        body: "Hello world"
      }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
      "data" => %{
        "createRoomMessage" => nil
      },
      "errors" => [%{
        "code" => "NOT_FOUND",
        "locations" => [%{"column" => 0, "line" => 5}],
        "message" => "Room not found",
        "path" => ["createRoomMessage"]
      }]
    }
  end
end
