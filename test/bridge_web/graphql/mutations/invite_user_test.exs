defmodule BridgeWeb.GraphQL.InviteUserTest do
  use BridgeWeb.ConnCase
  import BridgeWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, team: team}} = insert_signup()
    conn = authenticate_with_jwt(conn, team, user)
    {:ok, %{conn: conn, user: user, team: team}}
  end

  test "creates an invitation with valid data", %{conn: conn, user: user} do
    email = "tiffany@bridge.chat"

    query = """
      mutation {
        inviteUser(email: "#{email}") {
          success
          invitation {
            email
            invitor {
              email
            }
          }
          errors {
            attribute
            message
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
        "inviteUser" => %{
          "success" => true,
          "invitation" => %{
            "email" => email,
            "invitor" => %{
              "email" => user.email
            }
          },
          "errors" => []
        }
      }
    }
  end

  test "returns validation errors when data is valid", %{conn: conn} do
    email = "notvalid"

    query = """
      mutation {
        inviteUser(email: "#{email}") {
          success
          invitation {
            email
          }
          errors {
            attribute
            message
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
        "inviteUser" => %{
          "success" => false,
          "invitation" => nil,
          "errors" => [
            %{"attribute" => "email", "message" => "is invalid"}
          ]
        }
      }
    }
  end
end
