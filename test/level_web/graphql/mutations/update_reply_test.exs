defmodule LevelWeb.GraphQL.UpdateReplyTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation UpdateReply(
      $space_id: ID!,
      $reply_id: ID!,
      $body: String!
    ) {
      updateReply(
        spaceId: $space_id,
        replyId: $reply_id,
        body: $body
      ) {
        success
        reply {
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

  test "updates the reply if user is allowed", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)
    {:ok, %{reply: reply}} = create_reply(space_user, post, %{body: "Old body"})

    variables = %{space_id: space.id, reply_id: reply.id, body: "New body"}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "updateReply" => %{
                 "success" => true,
                 "reply" => %{
                   "body" => "New body"
                 },
                 "errors" => []
               }
             }
           }
  end
end
