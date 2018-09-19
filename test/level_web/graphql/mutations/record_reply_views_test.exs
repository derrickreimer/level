defmodule LevelWeb.GraphQL.RecordReplyViewsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation RecordReplyViews(
      $space_id: ID!,
      $reply_ids: [ID]!
    ) {
      recordReplyViews(
        spaceId: $space_id,
        replyIds: $reply_ids,
      ) {
        success
        errors {
          attribute
          message
        }
        replies {
          hasViewed
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user} = result} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, Map.put(result, :conn, conn)}
  end

  test "marks the replies as viewed", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    {:ok, %{space_user: another_user}} = create_space_member(space)
    {:ok, %{reply: first_reply}} = create_reply(another_user, post)
    {:ok, %{reply: second_reply}} = create_reply(another_user, post)

    variables = %{
      space_id: space.id,
      reply_ids: [first_reply.id, second_reply.id]
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "recordReplyViews" => %{
                 "success" => true,
                 "errors" => [],
                 "replies" => [
                   %{
                     "hasViewed" => true
                   },
                   %{
                     "hasViewed" => true
                   }
                 ]
               }
             }
           }
  end
end
