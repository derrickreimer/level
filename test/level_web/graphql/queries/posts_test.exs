defmodule LevelWeb.GraphQL.PostsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Mentions

  @query """
    query Posts(
      $space_id: ID!,
      $has_pings: Boolean,
      $order_field: PostOrderField!
    ) {
      space(id: $space_id) {
        posts(
          first: 2,
          hasPings: $has_pings,
          orderBy: { field: $order_field, direction: DESC }
        ) {
          edges {
            node {
              body
              mentions {
                mentioner {
                  handle
                }
              }
            }
          }
          total_count
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} =
      create_user_and_space(%{handle: "tiff"})

    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "filtering posts by has pings", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{space_user: another_user}} = create_space_member(space, %{handle: "derrick"})
    {:ok, %{post: _post}} = create_post(another_user, group, %{body: "Hey @tiff"})

    variables = %{
      space_id: space_user.space_id,
      has_pings: true,
      order_field: "LAST_PINGED_AT"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "posts" => %{
                   "edges" => [
                     %{
                       "node" => %{
                         "body" => "Hey @tiff",
                         "mentions" => [
                           %{
                             "mentioner" => %{
                               "handle" => "derrick"
                             }
                           }
                         ]
                       }
                     }
                   ],
                   "total_count" => 1
                 }
               }
             }
           }
  end

  test "filtering by has no pings excludes dismissed posts", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{space_user: another_user}} = create_space_member(space, %{handle: "derrick"})
    {:ok, %{post: post}} = create_post(another_user, group, %{body: "Hey @tiff"})

    Mentions.dismiss_all(space_user, [post.id])

    variables = %{
      space_id: space_user.space_id,
      has_pings: true,
      order_field: "LAST_PINGED_AT"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "posts" => %{
                   "edges" => [],
                   "total_count" => 0
                 }
               }
             }
           }
  end
end
