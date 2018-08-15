defmodule LevelWeb.GraphQL.MentionedPostsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Mentions

  @query """
    query MentionedPosts(
      $space_id: ID!
    ) {
      space(id: $space_id) {
        mentionedPosts(first: 2) {
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

  test "spaces have a paginated mentioned posts field", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{space_user: another_user}} = create_space_member(space, %{handle: "derrick"})
    {:ok, %{post: _post}} = create_post(another_user, group, %{body: "Hey @tiff"})

    variables = %{space_id: space_user.space_id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "mentionedPosts" => %{
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

  test "mentioned posts exclude dismissed mentions", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{space_user: another_user}} = create_space_member(space, %{handle: "derrick"})
    {:ok, %{post: post}} = create_post(another_user, group, %{body: "Hey @tiff"})

    Mentions.dismiss_all(space_user, post)
    variables = %{space_id: space_user.space_id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "mentionedPosts" => %{
                   "edges" => [],
                   "total_count" => 0
                 }
               }
             }
           }
  end
end
