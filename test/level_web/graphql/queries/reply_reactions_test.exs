defmodule LevelWeb.GraphQL.ReplyReactionsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Posts

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "replies expose whether the current user has reacted", %{
    conn: conn,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user, %{name: "Engineers"})
    {:ok, %{post: post}} = create_post(space_user, group, %{body: "Hello"})
    {:ok, %{reply: reply}} = create_reply(space_user, post)

    query = """
      query GetReplies(
        $space_id: ID!,
        $post_id: ID!,
        $last: Int!,
        $before: Cursor
      ) {
        space(id: $space_id) {
          post(id: $post_id) {
            replies(
              last: $last,
              before: $before
            ) {
              edges {
                node {
                  id
                  hasReacted
                }
              }
            }
          }
        }
      }
    """

    variables = %{
      space_id: space_user.space_id,
      post_id: post.id,
      last: 5
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "post" => %{
                   "replies" => %{
                     "edges" => [
                       %{
                         "node" => %{
                           "id" => reply.id,
                           "hasReacted" => false
                         }
                       }
                     ]
                   }
                 }
               }
             }
           }

    {:ok, _} = Posts.create_reply_reaction(space_user, post, reply)

    conn =
      conn
      |> recycle()
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "post" => %{
                   "replies" => %{
                     "edges" => [
                       %{
                         "node" => %{
                           "id" => reply.id,
                           "hasReacted" => true
                         }
                       }
                     ]
                   }
                 }
               }
             }
           }
  end

  test "replies has a reactions connection", %{
    conn: conn,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user, %{name: "Engineers"})
    {:ok, %{post: post}} = create_post(space_user, group, %{body: "Hello"})
    {:ok, %{reply: reply}} = create_reply(space_user, post)

    query = """
      query GetReplies(
        $space_id: ID!,
        $post_id: ID!,
        $last: Int!,
        $before: Cursor
      ) {
        space(id: $space_id) {
          post(id: $post_id) {
            replies(
              last: $last,
              before: $before
            ) {
              edges {
                node {
                  id
                  reactions(first: 10) {
                    totalCount
                  }
                }
              }
            }
          }
        }
      }
    """

    {:ok, _} = Posts.create_reply_reaction(space_user, post, reply)

    variables = %{
      space_id: space_user.space_id,
      post_id: post.id,
      last: 5
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "post" => %{
                   "replies" => %{
                     "edges" => [
                       %{
                         "node" => %{
                           "id" => reply.id,
                           "reactions" => %{
                             "totalCount" => 1
                           }
                         }
                       }
                     ]
                   }
                 }
               }
             }
           }
  end
end
