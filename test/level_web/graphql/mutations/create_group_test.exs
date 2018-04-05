defmodule LevelWeb.GraphQL.CreateGroupTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Groups

  @query """
    mutation CreateGroup(
      $name: String!
      $description: String,
      $isPrivate: Boolean
    ) {
      createGroup(
        name: $name,
        description: $description,
        isPrivate: $isPrivate
      ) {
        success
        group {
          name
          description
        }
        errors {
          attribute
          message
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)
    {:ok, %{conn: conn, user: user, space: space}}
  end

  test "creates a group given valid data", %{conn: conn} do
    variables = valid_group_params()

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createGroup" => %{
                 "success" => true,
                 "group" => %{
                   "name" => variables.name,
                   "description" => variables.description
                 },
                 "errors" => []
               }
             }
           }
  end

  test "returns validation errors when data is invalid", %{conn: conn} do
    variables =
      valid_group_params()
      |> Map.put(:name, "")

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createGroup" => %{
                 "success" => false,
                 "group" => nil,
                 "errors" => [
                   %{"attribute" => "name", "message" => "can't be blank"}
                 ]
               }
             }
           }
  end

  test "returns validation errors when uniqueness error occurs", %{conn: conn, user: user} do
    variables = valid_group_params()
    Groups.create_group(user, variables)

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createGroup" => %{
                 "success" => false,
                 "group" => nil,
                 "errors" => [
                   %{"attribute" => "name", "message" => "has already been taken"}
                 ]
               }
             }
           }
  end
end
