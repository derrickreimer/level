defmodule LevelWeb.GraphQL.MentionsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    query Mentions(
      $space_id: ID!
    ) {
      space(id: $space_id) {
        mentions(first: 2) {
          edges {
            node {
              post {
                body
              }
              mentioners {
                handle
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

  test "spaces have a paginated mentions field", %{
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
                 "mentions" => %{
                   "edges" => [
                     %{
                       "node" => %{
                         "post" => %{
                           "body" => "Hey @tiff"
                         },
                         "mentioners" => [
                           %{
                             "handle" => "derrick"
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
end
