defmodule LevelWeb.GraphQL.SearchTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    query Search(
      $space_id: ID!,
      $query: String!,
      $first: Int,
      $last: Int,
      $before: Cursor,
      $after: Cursor
    ) {
      space(id: $space_id) {
        search(
          query: $query,
          first: $first,
          last: $last,
          before: $before,
          after: $after
        ) {
          edges {
            node {
              preview
              post {
                id
              }
              reply {
                id
              }
            }
          }
          total_count
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "searches posts", %{conn: conn, space: space, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)

    {:ok, %{post: post}} =
      create_post(space_user, group, %{body: "Quick brown fox jumps over the lazy dog"})

    variables = %{
      space_id: space.id,
      query: "quick",
      first: 10
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "search" => %{
                   "edges" => [
                     %{
                       "node" => %{
                         "preview" => "<b>Quick</b> brown fox jumps over the lazy dog",
                         "post" => %{
                           "id" => post.id
                         },
                         "reply" => nil
                       }
                     }
                   ],
                   "total_count" => 1
                 }
               }
             }
           }
  end

  test "searches replies", %{conn: conn, space: space, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)

    {:ok, %{post: post}} = create_post(space_user, group)
    {:ok, %{reply: reply}} = create_reply(space_user, post, %{body: "Fighting uphill battles"})

    variables = %{
      space_id: space.id,
      query: "fight",
      first: 10
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "search" => %{
                   "edges" => [
                     %{
                       "node" => %{
                         "preview" => "<b>Fighting</b> uphill battles",
                         "post" => %{
                           "id" => post.id
                         },
                         "reply" => %{
                           "id" => reply.id
                         }
                       }
                     }
                   ],
                   "total_count" => 1
                 }
               }
             }
           }
  end
end
