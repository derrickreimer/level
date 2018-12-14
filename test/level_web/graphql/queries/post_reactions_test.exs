defmodule LevelWeb.GraphQL.PostReactions do
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
          reactions(
            last: $last,
            before: $before
          ) {
            edges {
              node {
                spaceUser {
                  id
                }
              }
            }
            totalCount
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

  test "posts have a reactions connection", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    {:ok, %{space_user: another_user}} = create_space_member(space)

    variables = %{
      space_id: space_user.space_id,
      post_id: post.id,
      last: 5
    }

    {:ok, _} = Posts.create_post_reaction(space_user, post)
    {:ok, _} = Posts.create_post_reaction(another_user, post)

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "post" => %{
                   "reactions" => %{
                     "edges" => [
                       %{
                         "node" => %{
                           "spaceUser" => %{
                             "id" => space_user.id
                           }
                         }
                       },
                       %{
                         "node" => %{
                           "spaceUser" => %{
                             "id" => another_user.id
                           }
                         }
                       }
                     ],
                     "totalCount" => 2
                   }
                 }
               }
             }
           }
  end
end
