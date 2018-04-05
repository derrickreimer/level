defmodule LevelWeb.GraphQL.InvitationsTest do
  use LevelWeb.ConnCase
  import LevelWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)

    {:ok, invitation} = insert_invitation(user)
    {:ok, %{conn: conn, user: user, space: space, invitation: invitation}}
  end

  test "returns pending invitations", %{conn: conn, invitation: invitation} do
    query = """
      query GetInvitations {
        viewer {
          space {
            invitations(first: 10) {
              edges {
                node {
                  id
                  email
                  insertedAt
                }
              }
              totalCount
            }
          }
        }
      }
    """

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query})

    assert json_response(conn, 200) == %{
             "data" => %{
               "viewer" => %{
                 "space" => %{
                   "invitations" => %{
                     "edges" => [
                       %{
                         "node" => %{
                           "id" => to_string(invitation.id),
                           "email" => invitation.email,
                           "insertedAt" =>
                             invitation.inserted_at
                             |> Timex.to_datetime()
                             |> DateTime.to_iso8601()
                         }
                       }
                     ],
                     "totalCount" => 1
                   }
                 }
               }
             }
           }
  end

  test "excludes non-pending invitations", %{conn: conn, invitation: invitation} do
    invitation
    |> Ecto.Changeset.change(%{state: "ACCEPTED"})
    |> Level.Repo.update()

    query = """
      query GetInvitations {
        viewer {
          space {
            invitations(first: 10) {
              totalCount
            }
          }
        }
      }
    """

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query})

    assert json_response(conn, 200) == %{
             "data" => %{
               "viewer" => %{
                 "space" => %{
                   "invitations" => %{
                     "totalCount" => 0
                   }
                 }
               }
             }
           }
  end
end
