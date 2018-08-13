defmodule LevelWeb.GraphQL.DismissMentionsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Mentions
  alias Level.Mentions.UserMention
  alias Level.Repo

  @query """
    mutation DismissMentions(
      $space_id: ID!,
      $post_id: ID!
    ) {
      dismissMentions(
        spaceId: $space_id,
        postId: $post_id
      ) {
        success
        post {
          id
        }
        errors {
          attribute
          message
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user} = result} = create_user_and_space(%{handle: "derrick"})
    conn = authenticate_with_jwt(conn, user)
    {:ok, Map.put(result, :conn, conn)}
  end

  test "dismisses mentions for the related post", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{space_user: another_user}} = create_space_member(space)
    {:ok, %{post: post}} = create_post(another_user, group, %{body: "Hey @derrick"})

    # verify that a mention in fact exists
    assert %UserMention{post_id: post_id} =
             Repo.get_by(Mentions.base_query(space_user), post_id: post.id)

    variables = %{
      space_id: space.id,
      post_id: post_id
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "dismissMentions" => %{
                 "success" => true,
                 "post" => %{
                   "id" => post.id
                 },
                 "errors" => []
               }
             }
           }

    assert Repo.get_by(Mentions.base_query(space_user), post_id: post.id) == nil
  end
end
