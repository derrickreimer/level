defmodule LevelWeb.GraphQL.DeletePostTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation DeletePost(
      $space_id: ID!,
      $post_id: ID!
    ) {
      deletePost(
        spaceId: $space_id,
        postId: $post_id
      ) {
        success
        post {
          state
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

  test "deletes the post if user is allowed", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    variables = %{space_id: space.id, post_id: post.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "deletePost" => %{
                 "success" => true,
                 "post" => %{
                   "state" => "DELETED"
                 },
                 "errors" => []
               }
             }
           }
  end
end
