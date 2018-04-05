defmodule LevelWeb.GraphQL.RevokeInvitationTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Spaces

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)
    {:ok, invitation} = Spaces.create_invitation(user, valid_invitation_params())
    {:ok, %{conn: conn, user: user, space: space, invitation: invitation}}
  end

  test "transitions the invitation to revoked", %{conn: conn, invitation: invitation} do
    query = """
      mutation RevokeInvitation(
        $id: ID!
      ) {
        revokeInvitation(id: $id) {
          success
          invitation {
            id
          }
          errors {
            attribute
            message
          }
        }
      }
    """

    variables = %{
      id: to_string(invitation.id)
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "revokeInvitation" => %{
                 "success" => true,
                 "invitation" => %{
                   "id" => to_string(invitation.id)
                 },
                 "errors" => []
               }
             }
           }

    revoked_invitation = Repo.get(Spaces.Invitation, invitation.id)
    assert revoked_invitation.state == "REVOKED"
  end

  test "returns errors if not found", %{conn: conn} do
    query = """
      mutation RevokeInvitation(
        $id: ID!
      ) {
        revokeInvitation(id: $id) {
          success
          errors {
            attribute
            message
          }
        }
      }
    """

    variables = %{
      id: Ecto.UUID.generate()
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "revokeInvitation" => %{
                 "success" => false,
                 "errors" => [
                   %{
                     "attribute" => "base",
                     "message" => "Invitation not found"
                   }
                 ]
               }
             }
           }
  end
end
