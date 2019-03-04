defmodule LevelWeb.GraphQL.SearchTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    query Search(
      $space_id: ID!,
      $query: String!,
      $page: Int,
      $count: Int
    ) {
      space(id: $space_id) {
        search(
          query: $query,
          page: $page,
          count: $count
        ) {
          pageInfo {
            hasPreviousPage
            hasNextPage
          }
          nodes {
            __typename
            ... on PostSearchResult {
              preview
              post {
                id
              }
            }

            ... on ReplySearchResult {
              preview
              post {
                id
              }
              reply {
                id
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

  test "searches posts", %{conn: conn, space: space, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)

    {:ok, %{post: post}} =
      create_post(space_user, group, %{body: "Quick brown fox jumps over the lazy dog"})

    variables = %{
      space_id: space.id,
      query: "quick",
      page: 1,
      count: 20
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "search" => %{
                   "pageInfo" => %{
                     "hasPreviousPage" => false,
                     "hasNextPage" => false
                   },
                   "nodes" => [
                     %{
                       "__typename" => "PostSearchResult",
                       "preview" => "<p><mark>Quick</mark> brown fox jumps over the lazy dog</p>",
                       "post" => %{
                         "id" => post.id
                       }
                     }
                   ]
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
      page: 1,
      count: 20
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "search" => %{
                   "pageInfo" => %{
                     "hasPreviousPage" => false,
                     "hasNextPage" => false
                   },
                   "nodes" => [
                     %{
                       "__typename" => "ReplySearchResult",
                       "preview" => "<p><mark>Fighting</mark> uphill battles</p>",
                       "post" => %{
                         "id" => post.id
                       },
                       "reply" => %{
                         "id" => reply.id
                       }
                     }
                   ]
                 }
               }
             }
           }
  end
end
