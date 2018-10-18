defmodule LevelWeb.GraphQL.MarkAsUnreadTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Posts

  @query """
    mutation MarkAsUnread(
      $space_id: ID!,
      $post_ids: [ID]!
    ) {
      markAsUnread(
        spaceId: $space_id,
        postIds: $post_ids
      ) {
        success
        posts {
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
    {:ok, %{user: user} = result} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, Map.put(result, :conn, conn)}
  end

  test "transitions inbox state to unread", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    Posts.dismiss(space_user, [post])

    variables = %{
      space_id: space.id,
      post_ids: [post.id]
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "markAsUnread" => %{
                 "success" => true,
                 "posts" => [
                   %{
                     "id" => post.id
                   }
                 ],
                 "errors" => []
               }
             }
           }

    assert %{inbox: "UNREAD"} = Posts.get_user_state(post, space_user)
  end
end
