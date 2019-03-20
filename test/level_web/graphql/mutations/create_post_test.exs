defmodule LevelWeb.GraphQL.CreatePostTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation CreatePost(
      $space_id: ID!,
      $group_id: ID,
      $recipient_ids: [ID],
      $body: String!
    ) {
      createPost(
        spaceId: $space_id,
        groupId: $group_id,
        recipientIds: $recipient_ids,
        body: $body
      ) {
        success
        post {
          body
          groups {
            id
          }
          recipients {
            id
          }
          author {
            actor {
              ... on SpaceUser {
                firstName
              }
            }
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
                   "recipients" => [
                     %{
                       "id" => space_user.id
                     }
                   ],
                   "author" => %{
                     "actor" => %{
                       "firstName" => user.first_name
                     }
                   }
                 },
                 "errors" => []
               }
             }
           }
  end

  test "creates a post with given recipients", %{
    conn: conn,
    user: user,
    space: space,
    space_user: space_user
  } do
    {:ok, %{space_user: another_user}} = create_space_member(space)

    variables =
      valid_post_params()
      |> Map.put(:body, "I am the body")
      |> Map.put(:space_id, space.id)
      |> Map.put(:recipient_ids, [another_user.id])

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
                   "groups" => [],
                   "recipients" => [
                     %{
                       "id" => space_user.id
                     },
                     %{
                       "id" => another_user.id
                     }
                   ],
                   "author" => %{
                     "actor" => %{
                       "firstName" => user.first_name
                     }
                   }
                 },
                 "errors" => []
               }
             }
           }
  end
end
