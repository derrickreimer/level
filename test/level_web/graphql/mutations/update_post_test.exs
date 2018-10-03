defmodule LevelWeb.GraphQL.UpdatePostTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation UpdatePost(
      $space_id: ID!,
      $post_id: ID!,
      $body: String!
    ) {
      updatePost(
        spaceId: $space_id,
        postId: $post_id,
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
    {:ok, %{user: user} = result} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, Map.put(result, :conn, conn)}
  end

  test "updates the post if user is allowed", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    variables = %{space_id: space.id, post_id: post.id, body: "New body"}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "updatePost" => %{
                 "success" => true,
                 "post" => %{
                   "body" => "New body"
                 },
                 "errors" => []
               }
             }
           }
  end
end
