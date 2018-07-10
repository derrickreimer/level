defmodule LevelWeb.GraphQL.PostTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    query GetPost(
      $space_id: ID!
      $post_id: ID!
    ) {
      space(id: $space_id) {
        post(id: $post_id) {
          body
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "spaces expose their posts", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user, %{name: "Engineers"})
    {:ok, %{post: post}} = post_to_group(space_user, group, %{body: "Hello"})

    variables = %{
      space_id: space_user.space_id,
      post_id: post.id
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "post" => %{
                   "body" => "Hello"
                 }
               }
             }
           }
  end

  test "spaces do not expose inaccessible posts", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{space_user: another_user}} = create_space_member(space)
    {:ok, %{group: group}} = create_group(another_user, %{name: "Top Secret", is_private: true})
    {:ok, %{post: post}} = post_to_group(another_user, group, %{body: "Hello"})

    variables = %{
      space_id: space_user.space_id,
      post_id: post.id
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{"space" => %{"post" => nil}},
             "errors" => [
               %{
                 "locations" => [%{"column" => 0, "line" => 6}],
                 "path" => ["space", "post"],
                 "message" => "Post not found"
               }
             ]
           }
  end
end
