defmodule LevelWeb.GraphQL.CreateReplyTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.File

  @query """
    mutation CreateReply(
      $space_id: ID!,
      $post_id: ID!,
      $body: String!,
      $file_ids: [ID]
    ) {
      createReply(
        spaceId: $space_id,
        postId: $post_id,
        body: $body,
        fileIds: $file_ids
      ) {
        success
        reply {
          body
          author {
            firstName
          }
          files {
            id
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

  test "creates a reply given valid data", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    variables =
      valid_post_params()
      |> Map.put(:body, "I am the body")
      |> Map.put(:space_id, space.id)
      |> Map.put(:post_id, post.id)

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createReply" => %{
                 "success" => true,
                 "reply" => %{
                   "body" => "I am the body",
                   "author" => %{
                     "firstName" => space_user.first_name
                   },
                   "files" => []
                 },
                 "errors" => []
               }
             }
           }
  end

  test "attaches file uploads", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)
    {:ok, %File{id: file_id}} = create_file(space_user)

    variables =
      valid_reply_params()
      |> Map.put(:body, "I am the body")
      |> Map.put(:space_id, space.id)
      |> Map.put(:post_id, post.id)
      |> Map.put(:file_ids, [file_id])

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createReply" => %{
                 "success" => true,
                 "reply" => %{
                   "body" => "I am the body",
                   "author" => %{
                     "firstName" => space_user.first_name
                   },
                   "files" => [
                     %{
                       "id" => file_id
                     }
                   ]
                 },
                 "errors" => []
               }
             }
           }
  end
end
