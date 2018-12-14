defmodule LevelWeb.GraphQL.CreateReplyReactionTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Posts

  @query """
    mutation CreateReplyReaction(
      $space_id: ID!,
      $post_id: ID!,
      $reply_id: ID!
    ) {
      createReplyReaction(
        spaceId: $space_id,
        postId: $post_id,
        replyId: $reply_id
      ) {
        success
        reply {
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

  test "creates a reaction", %{conn: conn, space: space, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)
    {:ok, %{reply: reply}} = create_reply(space_user, post)

    variables = %{space_id: space.id, post_id: post.id, reply_id: reply.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createReplyReaction" => %{
                 "success" => true,
                 "reply" => %{
                   "id" => reply.id
                 },
                 "errors" => []
               }
             }
           }

    assert Posts.reacted?(space_user, reply)
  end
end
