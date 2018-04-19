defmodule LevelWeb.GraphQL.CreatePostTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation CreatePost(
      $body: String!
    ) {
      createPost(
        body: $body
      ) {
        success
        post {
          body
        }
        errors {
          attribute
          message
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, space, user)
    {:ok, %{conn: conn, user: user, space: space}}
  end

  test "creates a post given valid data", %{conn: conn} do
    variables =
      valid_post_params()
      |> Map.put(:body, "I am the body")

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createPost" => %{
                 "success" => true,
                 "post" => %{
                   "body" => "I am the body"
                 },
                 "errors" => []
               }
             }
           }
  end
end
