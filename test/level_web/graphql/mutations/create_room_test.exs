defmodule LevelWeb.GraphQL.CreateRoomTest do
  use LevelWeb.ConnCase
  import LevelWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)

    query = """
      mutation CreateRoom(
        $name: String!,
        $description: String,
        $subscriberPolicy: RoomSubscriberPolicy!
      ) {
        createRoom(
          name: $name,
          description: $description,
          subscriberPolicy: $subscriberPolicy
        ) {
          room {
            name
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

    {:ok, %{conn: conn, user: user, space: space, query: query}}
  end

  test "creates a room with valid data",
    %{conn: conn, query: query} do

    variables = %{
      name: "Development",
      description: "A cool room",
      subscriberPolicy: "INVITE_ONLY"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
      "data" => %{
        "createRoom" => %{
          "success" => true,
          "room" => %{
            "name" => variables.name,
            "subscriberPolicy" => "INVITE_ONLY"
          },
          "errors" => []
        }
      }
    }
  end

  test "returns validation errors when data is invalid",
    %{conn: conn, user: user, query: query} do

    # create an existing room with the same name
    Level.Rooms.create_room(user, %{name: "Development"})

    variables = %{
      name: "Development",
      isPrivate: true
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
      "data" => %{
        "createRoom" => %{
          "success" => false,
          "room" => nil,
          "errors" => [
            %{"attribute" => "name", "message" => "has already been taken"}
          ]
        }
      }
    }
  end
end
