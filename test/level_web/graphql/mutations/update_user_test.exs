defmodule LevelWeb.GraphQL.UpdateUserTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation UpdateUser(
      $first_name: String,
      $last_name: String,
      $email: String
    ) {
      updateUser(
        firstName: $first_name,
        lastName: $last_name,
        email: $email
      ) {
        success
        user {
          firstName
          lastName
          email
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

  test "updates the authenticated user given valid data", %{conn: conn} do
    variables = %{first_name: "Saint", last_name: "Paul", email: "paul@gmail.com"}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "updateUser" => %{
                 "success" => true,
                 "user" => %{
                   "firstName" => "Saint",
                   "lastName" => "Paul",
                   "email" => "paul@gmail.com"
                 },
                 "errors" => []
               }
             }
           }
  end

  test "returns validation errors given invalid data", %{conn: conn} do
    variables = %{first_name: ""}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "updateUser" => %{
                 "success" => false,
                 "user" => nil,
                 "errors" => [
                   %{
                     "attribute" => "firstName",
                     "message" => "can't be blank"
                   }
                 ]
               }
             }
           }
  end
end
