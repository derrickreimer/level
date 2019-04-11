defmodule LevelWeb.GraphQL.CreatePostReactionTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation CreatePostReaction(
      $space_id: ID!,
      $post_id: ID!,
      $value: String!
    ) {
      createPostReaction(
        spaceId: $space_id,
        postId: $post_id,
        value: $value
      ) {
        success
        post {
          id
        }
        reaction {
          value
        }
        errors {
          attribute
          message
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "creates a reaction", %{conn: conn, space: space, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    variables = %{space_id: space.id, post_id: post.id, value: "👍"}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createPostReaction" => %{
                 "success" => true,
                 "post" => %{
                   "id" => post.id
                 },
                 "reaction" => %{
                   "value" => "👍"
                 },
                 "errors" => []
               }
             }
           }
  end

  test "errors out if reaction is too long", %{conn: conn, space: space, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    variables = %{space_id: space.id, post_id: post.id, value: "12345678912345678"}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createPostReaction" => %{
                 "errors" => [
                   %{"attribute" => "value", "message" => "should be at most 16 character(s)"}
                 ],
                 "post" => nil,
                 "reaction" => nil,
                 "success" => false
               }
             }
           }
  end
end
