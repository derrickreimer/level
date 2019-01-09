defmodule LevelWeb.GraphQL.GroupTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} =
      create_user_and_space(%{}, %{slug: "level"})

    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "groups are fetchable by id", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user, %{name: "engineers"})

    query = """
      query GetGroup(
        $group_id: ID!
      ) {
        group(id: $group_id) {
          name
        }
      }
    """

    variables = %{
      group_id: group.id
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "group" => %{
                 "name" => "engineers"
               }
             }
           }
  end

  test "groups are fetchable by space slug + name", %{conn: conn, space_user: space_user} do
    {:ok, %{group: _group}} = create_group(space_user, %{name: "engineers"})

    query = """
      query GetGroup(
        $space_slug: String!,
        $name: String!
      ) {
        group(spaceSlug: $space_slug, name: $name) {
          name
        }
      }
    """

    variables = %{
      space_slug: "level",
      name: "engineers"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "group" => %{
                 "name" => "engineers"
               }
             }
           }
  end

  test "errors out when not given proper info", %{conn: conn} do
    query = """
      query GetGroup {
        group {
          name
        }
      }
    """

    variables = %{}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{"group" => nil},
             "errors" => [
               %{
                 "locations" => [%{"column" => 0, "line" => 2}],
                 "message" => "You must provide an `id` or `space_slug` and `name` combo.",
                 "path" => ["group"]
               }
             ]
           }
  end
end
