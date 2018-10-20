defmodule LevelWeb.GraphQL.RecordPostViewTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Repo
  alias Level.Schemas.PostView

  @query """
    mutation RecordPostView(
      $space_id: ID!,
      $post_id: ID!,
      $reply_id: ID
    ) {
      recordPostView(
        spaceId: $space_id,
        postId: $post_id,
        lastViewedReplyId: $reply_id
      ) {
        success
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

  test "records a post view", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    variables = %{
      space_id: space.id,
      post_id: post.id
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "recordPostView" => %{
                 "success" => true,
                 "errors" => []
               }
             }
           }

    assert Repo.get_by(PostView, %{post_id: post.id, space_user_id: space_user.id}) != nil
  end
end
