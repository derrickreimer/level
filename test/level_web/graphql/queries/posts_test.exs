defmodule LevelWeb.GraphQL.PostsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Posts

  @query """
    query Posts(
      $space_id: ID!,
      $watching: WatchingFilter,
      $inbox: InboxFilter,
      $order_field: PostOrderField
    ) {
      space(id: $space_id) {
        posts(
          first: 10,
          filter: {
            watching: $watching,
            inbox: $inbox
          },
          orderBy: {
            field: $order_field,
            direction: DESC
          }
        ) {
          edges {
            node {
              body
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

  test "filtering by 'is watching' excludes posts the user is not watching", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    # Create a post in a public group that space user can _see_, but is not subscribed to
    {:ok, %{space_user: another_user}} = create_space_member(space, %{handle: "derrick"})
    {:ok, %{group: group}} = create_group(another_user)
    {:ok, %{post: _post}} = create_post(another_user, group, %{body: "I'm just opining..."})

    variables = %{
      space_id: space_user.space_id,
      watching: "IS_WATCHING"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "posts" => %{
                   "edges" => [],
                   "total_count" => 0
                 }
               }
             }
           }
  end

  test "filtering by unread", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: unread_post}} = create_post(space_user, group, %{body: "I'm just opining..."})
    {:ok, %{post: read_post}} = create_post(space_user, group, %{body: "Hey peeps"})

    Posts.mark_as_unread(space_user, [unread_post])
    Posts.mark_as_read(space_user, [read_post])

    variables = %{
      space_id: space_user.space_id,
      inbox: "UNREAD"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "posts" => %{
                   "edges" => [
                     %{
                       "node" => %{
                         "body" => "I'm just opining..."
                       }
                     }
                   ],
                   "total_count" => 1
                 }
               }
             }
           }
  end

  test "filtering by undismissed", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: unread_post}} = create_post(space_user, group, %{body: "I'm just opining..."})
    {:ok, %{post: read_post}} = create_post(space_user, group, %{body: "Hey peeps"})
    {:ok, %{post: dismissed_post}} = create_post(space_user, group, %{body: "I'm dismissed"})

    Posts.mark_as_unread(space_user, [unread_post])
    Posts.mark_as_read(space_user, [read_post])
    Posts.dismiss(space_user, [dismissed_post])

    variables = %{
      space_id: space_user.space_id,
      inbox: "UNDISMISSED"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "posts" => %{
                   "edges" => [
                     %{
                       "node" => %{
                         "body" => "Hey peeps"
                       }
                     },
                     %{
                       "node" => %{
                         "body" => "I'm just opining..."
                       }
                     }
                   ],
                   "total_count" => 2
                 }
               }
             }
           }
  end

  test "filtering by dismissed", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: unread_post}} = create_post(space_user, group, %{body: "I'm just opining..."})
    {:ok, %{post: read_post}} = create_post(space_user, group, %{body: "Hey peeps"})
    {:ok, %{post: dismissed_post}} = create_post(space_user, group, %{body: "I'm dismissed"})

    Posts.mark_as_unread(space_user, [unread_post])
    Posts.mark_as_read(space_user, [read_post])
    Posts.dismiss(space_user, [dismissed_post])

    variables = %{
      space_id: space_user.space_id,
      inbox: "DISMISSED"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "posts" => %{
                   "edges" => [
                     %{
                       "node" => %{
                         "body" => "I'm dismissed"
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
