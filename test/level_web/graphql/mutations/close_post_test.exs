defmodule LevelWeb.GraphQL.ClosePostTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Posts
  alias Level.Posts.Post

  @query """
    mutation ClosePost(
      $space_id: ID!,
      $post_id: ID!
    ) {
      closePost(
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

  test "closes the post", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    assert post.state == "OPEN"

    variables = %{space_id: space.id, post_id: post.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "closePost" => %{
                 "success" => true,
                 "post" => %{
                   "state" => "CLOSED"
                 },
                 "errors" => []
               }
             }
           }

    assert {:ok, %Post{state: "CLOSED"}} = Posts.get_post(space_user, post.id)
  end
end
