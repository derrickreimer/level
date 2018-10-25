defmodule LevelWeb.GraphQL.UpdateSpaceTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Spaces

  @query """
    mutation UpdateSpace(
      $space_id: ID!,
      $name: String,
      $slug: String,
    ) {
      updateSpace(
        spaceId: $space_id,
        name: $name,
        slug: $slug,
      ) {
        success
        space {
          name
        }
        errors {
          attribute
          message
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "updates a space given valid data", %{conn: conn, space: space} do
    variables = %{space_id: space.id, name: "New name"}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "updateSpace" => %{
                 "success" => true,
                 "space" => %{
                   "name" => "New name"
                 },
                 "errors" => []
               }
             }
           }
  end

  test "returns validation errors given invalid data", %{conn: conn, space: space} do
    variables = %{space_id: space.id, name: ""}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "updateSpace" => %{
                 "success" => false,
                 "space" => nil,
                 "errors" => [
                   %{
                     "attribute" => "name",
                     "message" => "can't be blank"
                   }
                 ]
               }
             }
           }
  end

  test "returns top-level error out user is not allowed", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    # Members are not allowed to update spaces
    Spaces.update_space_user(space_user, %{role: "MEMBER"})

    variables = %{space_id: space.id, name: "New name"}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{"updateSpace" => nil},
             "errors" => [
               %{
                 "locations" => [%{"column" => 0, "line" => 6}],
                 "message" => "You are not authorized to perform this action.",
                 "path" => ["updateSpace"]
               }
             ]
           }
  end

  test "returns top-level error out if space does not exist", %{conn: conn} do
    variables = %{space_id: Ecto.UUID.generate(), name: "New name"}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{"updateSpace" => nil},
             "errors" => [
               %{
                 "locations" => [%{"column" => 0, "line" => 6}],
                 "message" => "Space not found",
                 "path" => ["updateSpace"]
               }
             ]
           }
  end
end
