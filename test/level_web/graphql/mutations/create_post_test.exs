defmodule LevelWeb.GraphQL.CreatePostTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation CreatePost(
      $space_id: ID!,
      $body: String!
    ) {
      createPost(
        spaceId: $space_id,
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
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space}}
  end

  test "creates a post given valid data", %{conn: conn, space: space} do
    variables =
      valid_post_params()
      |> Map.put(:body, "I am the body")
      |> Map.put(:space_id, space.id)

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
