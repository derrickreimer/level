defmodule LevelWeb.GraphQL.CreateReplyReactionTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation CreateReplyReaction(
      $space_id: ID!,
      $post_id: ID!,
      $reply_id: ID!,
      $value: String!
    ) {
      createReplyReaction(
        spaceId: $space_id,
        postId: $post_id,
        replyId: $reply_id,
        value: $value
      ) {
        success
        reply {
          id
        }
        reaction {
          value
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

    variables = %{space_id: space.id, post_id: post.id, reply_id: reply.id, value: "👍"}

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
                 "reaction" => %{
                   "value" => "👍"
                 },
                 "errors" => []
               }
             }
           }
  end

  test "errors out if reaction is too long", %{conn: conn, space: space, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)
    {:ok, %{reply: reply}} = create_reply(space_user, post)

    variables = %{
      space_id: space.id,
      post_id: post.id,
      reply_id: reply.id,
      value: "12345678912345678"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createReplyReaction" => %{
                 "errors" => [
                   %{"attribute" => "value", "message" => "should be at most 16 character(s)"}
                 ],
                 "reply" => nil,
                 "reaction" => nil,
                 "success" => false
               }
             }
           }
  end
end
