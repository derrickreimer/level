defmodule LevelWeb.GraphQL.CreatePostTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation CreatePost(
      $space_id: ID!,
      $group_id: ID!,
      $body: String!
    ) {
      createPost(
        spaceId: $space_id,
        groupId: $group_id,
        body: $body
      ) {
        success
        post {
          body
          groups {
            id
          }
          author {
            firstName
          }
        }
        errors {
          attribute
          message
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user} = result} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, Map.put(result, :conn, conn)}
  end

  test "creates a post given valid data", %{
    conn: conn,
    user: user,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)

    variables =
      valid_post_params()
      |> Map.put(:body, "I am the body")
      |> Map.put(:space_id, space.id)
      |> Map.put(:group_id, group.id)

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createPost" => %{
                 "success" => true,
                 "post" => %{
                   "body" => "I am the body",
                   "groups" => [
                     %{
                       "id" => group.id
                     }
                   ],
                   "author" => %{
                     "firstName" => user.first_name
                   }
                 },
                 "errors" => []
               }
             }
           }
  end
end
