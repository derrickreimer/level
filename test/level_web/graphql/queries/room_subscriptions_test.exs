defmodule LevelWeb.GraphQL.RoomSubscriptionsTest do
  use LevelWeb.ConnCase
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Rooms

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)
    {:ok, %{conn: conn, user: user, space: space}}
  end

  test "returns room subscriptions for the user", %{conn: conn} do
    query = """
      {
        viewer {
          roomSubscriptions(first: 10) {
            edges {
              node {
                room {
                  name
                }
              }
            }
            total_count
          }
        }
      }
    """

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", query)

    assert json_response(conn, 200) == %{
      "data" => %{
        "viewer" => %{
          "roomSubscriptions" => %{
            "edges" => [%{
              "node" => %{
                "room" => %{
                  "name" => "Everyone"
                }
              }
            }],
            "total_count" => 1
          }
        }
      }
    }
  end

  test "fetches the last read message", %{conn: conn, user: user} do
    subscription =
      Rooms.RoomSubscription
      |> Repo.get_by(%{user_id: user.id})
      |> Repo.preload(:room)

    # Insert a message
    {:ok, message} =
      subscription.room
      |> Rooms.create_message(user, valid_room_message_params())

    # Set the newly-created message as the last read one
    subscription
    |> Ecto.Changeset.change(%{last_read_message_id: message.id})
    |> Repo.update()

    query = """
      {
        viewer {
          roomSubscriptions(first: 10) {
            edges {
              node {
                lastReadMessage {
                  id
                }
              }
            }
            total_count
          }
        }
      }
    """

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", query)

    assert json_response(conn, 200) == %{
      "data" => %{
        "viewer" => %{
          "roomSubscriptions" => %{
            "edges" => [%{
              "node" => %{
                "lastReadMessage" => %{
                  "id" => to_string(message.id)
                }
              }
            }],
            "total_count" => 1
          }
        }
      }
    }
  end
end
