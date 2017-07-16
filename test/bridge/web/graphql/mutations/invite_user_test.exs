defmodule Bridge.Web.GraphQL.InviteUserTest do
  use Bridge.Web.ConnCase
  import Bridge.Web.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, team: team}} = insert_signup()
    conn = authenticate_with_jwt(conn, team, user)
    {:ok, %{conn: conn, user: user, team: team}}
  end

  test "creates an invitation with valid data", %{conn: conn} do
    email = "tiffany@bridge.chat"

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
          "success" => true,
          "invitation" => %{
            "email" => email
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
