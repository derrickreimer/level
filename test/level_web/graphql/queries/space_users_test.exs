defmodule LevelWeb.GraphQL.SpaceUsersTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @single_query """
    query GetSpaceUser(
      $id: ID,
      $space_id: ID
    ) {
      spaceUser(id: $id, spaceId: $space_id) {
        role
        space {
          name
        }
        firstName
        lastName
      }
    }
  """

  @list_query """
    {
      viewer {
        spaceUsers(first: 10, orderBy: { field: LAST_NAME, direction: ASC }) {
          edges {
            node {
              space {
                name
              }
              firstName
              lastName
            }
          }
        }
      }
    }
  """

  @space_list_query """
    query GetSpaceUsers(
      $space_id: ID!
    ) {
      space(id: $space_id) {
        spaceUsers(first: 10, orderBy: { field: LAST_NAME, direction: ASC }) {
          edges {
            node {
              lastName
            }
          }
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, user} = create_user(%{last_name: "Anderson"})
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user}}
  end

  test "users can lookup their own membership by space id", %{conn: conn, user: user} do
    {:ok, %{space: space}} = create_space(user, %{name: "Level"})

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @single_query, variables: %{space_id: space.id}})

    assert json_response(conn, 200) == %{
             "data" => %{
               "spaceUser" => %{
                 "role" => "OWNER",
                 "space" => %{
                   "name" => "Level"
                 },
                 "firstName" => user.first_name,
                 "lastName" => user.last_name
               }
             }
           }
  end

  test "users can lookup a membership by id", %{conn: conn, user: user} do
    {:ok, %{space: space}} = create_space(user, %{name: "Level"})

    {:ok, %{space_user: another_member}} =
      create_space_member(space, %{first_name: "Jane", last_name: "Doe"})

    variables = %{id: another_member.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @single_query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "spaceUser" => %{
                 "role" => "MEMBER",
                 "space" => %{
                   "name" => "Level"
                 },
                 "firstName" => "Jane",
                 "lastName" => "Doe"
               }
             }
           }
  end

  test "users can list their space memberships", %{conn: conn, user: user} do
    {:ok, %{space: _space}} = create_space(user, %{name: "Level"})

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", @list_query)

    assert json_response(conn, 200) == %{
             "data" => %{
               "viewer" => %{
                 "spaceUsers" => %{
                   "edges" => [
                     %{
                       "node" => %{
                         "space" => %{
                           "name" => "Level"
                         },
                         "firstName" => user.first_name,
                         "lastName" => user.last_name
                       }
                     }
                   ]
                 }
               }
             }
           }
  end

  test "users can list members of a space", %{conn: conn, user: user} do
    {:ok, %{space: space}} = create_space(user, %{name: "Level"})
    {:ok, %{space_user: _}} = create_space_member(space, %{last_name: "Baker"})

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @space_list_query, variables: %{space_id: space.id}})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "spaceUsers" => %{
                   "edges" => [
                     %{
                       "node" => %{
                         "lastName" => "Anderson"
                       }
                     },
                     %{
                       "node" => %{
                         "lastName" => "Baker"
                       }
                     }
                   ]
                 }
               }
             }
           }
  end
end
