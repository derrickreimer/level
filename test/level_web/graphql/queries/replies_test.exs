defmodule LevelWeb.GraphQL.RepliesTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Posts

  @query """
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
                hasViewed
              }
            }
          }
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "replies indicate when they have not been viewed", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user, %{name: "Engineers"})
    {:ok, %{post: post}} = create_post(space_user, group, %{body: "Hello"})

    {:ok, %{space_user: another_user}} = create_space_member(space)
    {:ok, %{reply: reply}} = create_reply(another_user, post)

    variables = %{
      space_id: space_user.space_id,
      post_id: post.id,
      last: 5
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "post" => %{
                   "replies" => %{
                     "edges" => [
                       %{
                         "node" => %{
                           "id" => reply.id,
                           "hasViewed" => false
                         }
                       }
                     ]
                   }
                 }
               }
             }
           }
  end

  test "replies indicate when they have been viewed", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user, %{name: "Engineers"})
    {:ok, %{post: post}} = create_post(space_user, group, %{body: "Hello"})

    {:ok, %{space_user: another_user}} = create_space_member(space)
    {:ok, %{reply: reply}} = create_reply(another_user, post)

    Posts.record_reply_views(space_user, [reply])

    variables = %{
      space_id: space_user.space_id,
      post_id: post.id,
      last: 5
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "post" => %{
                   "replies" => %{
                     "edges" => [
                       %{
                         "node" => %{
                           "id" => reply.id,
                           "hasViewed" => true
                         }
                       }
                     ]
                   }
                 }
               }
             }
           }
  end

  test "users can edit their own replies", %{
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
                  canEdit
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
                           "canEdit" => true
                         }
                       }
                     ]
                   }
                 }
               }
             }
           }
  end

  test "users cannot edit others' replies", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user, %{name: "Engineers"})
    {:ok, %{post: post}} = create_post(space_user, group, %{body: "Hello"})

    {:ok, %{space_user: another_user}} = create_space_member(space)
    {:ok, %{reply: reply}} = create_reply(another_user, post)

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
                  canEdit
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
                           "canEdit" => false
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
