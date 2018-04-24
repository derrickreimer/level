defmodule LevelWeb.GraphQL.CreateGroupTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Groups

  @query """
    mutation CreateGroup(
      $space_id: ID!,
      $name: String!,
      $description: String,
      $is_private: Boolean
    ) {
      createGroup(
        spaceId: $space_id,
        name: $name,
        description: $description,
        isPrivate: $is_private
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
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "creates a group given valid data", %{conn: conn, space: space} do
    variables =
      valid_group_params()
      |> Map.put(:space_id, space.id)

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

  test "returns validation errors when data is invalid", %{conn: conn, space: space} do
    variables =
      valid_group_params()
      |> Map.put(:space_id, space.id)
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

  test "returns validation errors when uniqueness error occurs", %{
    conn: conn,
    space_user: space_user
  } do
    variables = valid_group_params()

    Groups.create_group(space_user, variables)

    variables =
      variables
      |> Map.put(:space_id, space_user.space_id)

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
