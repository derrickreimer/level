defmodule LevelWeb.GraphQL.SearchTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    query Search(
      $space_id: ID!,
      $query: String!,
      $limit: Int,
      $cursor: Timestamp
    ) {
      space(id: $space_id) {
        search(
          query: $query,
          limit: $limit,
          cursor: $cursor
        ) {
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
      limit: 20
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "search" => [
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
  end

  test "searches replies", %{conn: conn, space: space, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)

    {:ok, %{post: post}} = create_post(space_user, group)
    {:ok, %{reply: reply}} = create_reply(space_user, post, %{body: "Fighting uphill battles"})

    variables = %{
      space_id: space.id,
      query: "fight",
      limit: 20
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "search" => [
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
  end
end
