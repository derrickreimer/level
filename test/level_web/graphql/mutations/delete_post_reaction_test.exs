defmodule LevelWeb.GraphQL.DeletePostReactionTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Posts
  alias Level.Schemas.Post

  @query """
    mutation DeletePostReaction(
      $space_id: ID!,
      $post_id: Int!
    ) {
      deletePostReaction(
        spaceId: $space_id,
        postId: $post_id
      ) {
        success
        post {
          id
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

  test "deletes a reaction", %{conn: conn, space: space, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: %Post{id: post_id} = post}} = create_post(space_user, group)

    {:ok, _} = Posts.create_post_reaction(space_user, post)

    variables = %{space_id: space.id, post_id: post_id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "deletePostReaction" => %{
                 "success" => true,
                 "post" => %{
                   "id" => post_id
                 },
                 "errors" => []
               }
             }
           }

    refute Posts.reacted?(space_user, post)
  end
end
