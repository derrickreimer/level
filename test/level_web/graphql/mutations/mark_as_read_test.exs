defmodule LevelWeb.GraphQL.MarkAsReadTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Posts

  @query """
    mutation MarkAsRead(
      $space_id: ID!,
      $post_ids: [ID]!
    ) {
      markAsRead(
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

  test "transitions inbox state to read", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    Posts.mark_as_unread(space_user, [post])

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
               "markAsRead" => %{
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

    assert %{inbox: "READ"} = Posts.get_user_state(post, space_user)
  end
end
