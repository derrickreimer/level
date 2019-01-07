defmodule LevelWeb.GraphQL.PostTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Posts

  @query """
    query GetPost(
      $space_id: ID!
      $post_id: ID!
    ) {
      space(id: $space_id) {
        post(id: $post_id) {
          body
          mentions {
            mentioner {
              id
            }
            reply {
              id
            }
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

  test "spaces expose their posts", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user, %{name: "engineers"})
    {:ok, %{post: post}} = create_post(space_user, group, %{body: "Hello"})

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
                   "body" => "Hello",
                   "mentions" => []
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
    {:ok, %{group: group}} = create_group(another_user, %{name: "top-secret", is_private: true})
    {:ok, %{post: post}} = create_post(another_user, group, %{body: "Hello"})

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

  test "posts expose mentions", %{conn: conn, space: space, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user, %{name: "engineers"})
    {:ok, %{post: post}} = create_post(space_user, group, %{body: "Hello"})

    {:ok, %{space_user: another_user}} = create_space_member(space)

    {:ok, %{reply: reply}} =
      create_reply(another_user, post, %{body: "Hey @#{space_user.handle}"})

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
                   "body" => "Hello",
                   "mentions" => [
                     %{
                       "mentioner" => %{
                         "id" => another_user.id
                       },
                       "reply" => %{
                         "id" => reply.id
                       }
                     }
                   ]
                 }
               }
             }
           }
  end

  test "users can edit their own posts", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user, %{name: "engineers"})
    {:ok, %{post: post}} = create_post(space_user, group, %{body: "Hello"})

    query = """
      query GetPost(
        $space_id: ID!
        $post_id: ID!
      ) {
        space(id: $space_id) {
          post(id: $post_id) {
            canEdit
          }
        }
      }
    """

    variables = %{
      space_id: space_user.space_id,
      post_id: post.id
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "post" => %{
                   "canEdit" => true
                 }
               }
             }
           }
  end

  test "users cannot edit other people's posts", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{space_user: another_user}} = create_space_member(space)
    {:ok, %{group: group}} = create_group(space_user, %{name: "engineers"})
    {:ok, %{post: post}} = create_post(another_user, group, %{body: "Hello"})

    query = """
      query GetPost(
        $space_id: ID!
        $post_id: ID!
      ) {
        space(id: $space_id) {
          post(id: $post_id) {
            canEdit
          }
        }
      }
    """

    variables = %{
      space_id: space_user.space_id,
      post_id: post.id
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "post" => %{
                   "canEdit" => false
                 }
               }
             }
           }
  end

  test "exposes the reaction state", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: post}} = create_post(space_user, group)

    query = """
      query GetPost(
        $space_id: ID!
        $post_id: ID!
      ) {
        space(id: $space_id) {
          post(id: $post_id) {
            hasReacted
          }
        }
      }
    """

    variables = %{
      space_id: space_user.space_id,
      post_id: post.id
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "post" => %{
                   "hasReacted" => false
                 }
               }
             }
           }

    {:ok, _} = Posts.create_post_reaction(space_user, post)

    conn =
      conn
      |> recycle()
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "post" => %{
                   "hasReacted" => true
                 }
               }
             }
           }
  end
end
