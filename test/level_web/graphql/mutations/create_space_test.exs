defmodule LevelWeb.GraphQL.CreateSpaceTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation CreateSpace(
      $name: String!,
      $slug: String!,
    ) {
      createSpace(
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
    {:ok, user} = create_user()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user}}
  end

  test "creates a space given valid data", %{conn: conn} do
    variables =
      valid_space_params()
      |> Map.put(:name, "MySpace")

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createSpace" => %{
                 "success" => true,
                 "space" => %{
                   "name" => "MySpace"
                 },
                 "errors" => []
               }
             }
           }
  end

  test "returns validation errors when data is invalid", %{conn: conn} do
    variables =
      valid_space_params()
      |> Map.put(:name, "")

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createSpace" => %{
                 "success" => false,
                 "space" => nil,
                 "errors" => [
                   %{"attribute" => "name", "message" => "can't be blank"}
                 ]
               }
             }
           }
  end
end
