defmodule LevelWeb.GraphQL.GroupViewerMembershipTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  import Ecto.Query
  alias Level.Groups
  alias Level.Groups.GroupUser

  @query """
    query GetGroupMembership(
      $group_id: ID!
    ) {
      group(id: $group_id) {
        membership {
          state
          spaceUser {
            id
          }
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "groups expose the current viewer's membership", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user, %{name: "Cool peeps"})
    Groups.create_group_membership(group, space_user)
    variables = %{group_id: group.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "group" => %{
                 "membership" => %{
                   "state" => "SUBSCRIBED",
                   "spaceUser" => %{
                     "id" => space_user.id
                   }
                 }
               }
             }
           }
  end

  test "group membership field is nil if viewer is not a member", %{
    conn: conn,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user, %{name: "Cool peeps"})

    Repo.delete_all(
      from gu in GroupUser, where: gu.space_user_id == ^space_user.id and gu.group_id == ^group.id
    )

    variables = %{group_id: group.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "group" => %{
                 "membership" => nil
               }
             }
           }
  end
end
