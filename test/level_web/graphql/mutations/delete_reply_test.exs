defmodule LevelWeb.GraphQL.DeleteReplyTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation DeleteReply(
      $space_id: ID!,
      $reply_id: ID!
    ) {
      deleteReply(
        spaceId: $space_id,
        replyId: $reply_id
      ) {
        success
        reply {
          isDeleted
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

  test "deletes the reply if user is allowed", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)
    {:ok, %{reply: reply}} = create_reply(space_user, post)

    variables = %{space_id: space.id, reply_id: reply.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "deleteReply" => %{
                 "success" => true,
                 "reply" => %{
                   "isDeleted" => true
                 },
                 "errors" => []
               }
             }
           }
  end
end
