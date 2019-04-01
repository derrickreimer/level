defmodule LevelWeb.GraphQL.PostsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Posts

  @query """
    query Posts(
      $space_id: ID!,
      $following_state: FollowingStateFilter,
      $inbox_state: InboxStateFilter,
      $state: PostStateFilter,
      $last_activity: LastActivityFilter,
      $privacy: PrivacyFilter,
      $author: String,
      $recipients: [String]
    ) {
      space(id: $space_id) {
        posts(
          first: 10,
          filter: {
            followingState: $following_state,
            inboxState: $inbox_state,
            state: $state,
            lastActivity: $last_activity,
            privacy: $privacy,
            author: $author,
            recipients: $recipients
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

  test "filtering by 'is following' excludes posts the user is not following", %{
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
      following_state: "IS_FOLLOWING"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    %{
      "data" => %{
        "space" => %{
          "posts" => %{
            "edges" => edges
          }
        }
      }
    } = json_response(conn, 200)

    refute Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "I'm just opining..."
           end)
  end

  test "filtering by unread", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: unread_post}} = create_post(space_user, group, %{body: "I'm just opining..."})
    {:ok, %{post: read_post}} = create_post(space_user, group, %{body: "Hey peeps"})

    Posts.mark_as_unread(space_user, [unread_post])
    Posts.mark_as_read(space_user, [read_post])

    variables = %{
      space_id: space_user.space_id,
      inbox_state: "UNREAD"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    %{
      "data" => %{
        "space" => %{
          "posts" => %{
            "edges" => edges
          }
        }
      }
    } = json_response(conn, 200)

    assert Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "I'm just opining..."
           end)

    refute Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "Hey peeps"
           end)
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
      inbox_state: "UNDISMISSED"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    %{
      "data" => %{
        "space" => %{
          "posts" => %{
            "edges" => edges
          }
        }
      }
    } = json_response(conn, 200)

    assert Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "I'm just opining..."
           end)

    assert Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "Hey peeps"
           end)

    refute Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "I'm dismissed"
           end)
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
      inbox_state: "DISMISSED"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    %{
      "data" => %{
        "space" => %{
          "posts" => %{
            "edges" => edges
          }
        }
      }
    } = json_response(conn, 200)

    refute Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "I'm just opining..."
           end)

    refute Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "Hey peeps"
           end)

    assert Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "I'm dismissed"
           end)
  end

  test "filtering by open", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: _open_post}} = create_post(space_user, group, %{body: "I'm open"})
    {:ok, %{post: closed_post}} = create_post(space_user, group, %{body: "I'm closed"})

    Posts.close_post(space_user, closed_post)

    variables = %{
      space_id: space_user.space_id,
      state: "OPEN"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    %{
      "data" => %{
        "space" => %{
          "posts" => %{
            "edges" => edges
          }
        }
      }
    } = json_response(conn, 200)

    refute Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "I'm closed"
           end)

    assert Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "I'm open"
           end)
  end

  test "filtering by closed", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: _open_post}} = create_post(space_user, group, %{body: "I'm open"})
    {:ok, %{post: closed_post}} = create_post(space_user, group, %{body: "I'm closed"})

    Posts.close_post(space_user, closed_post)

    variables = %{
      space_id: space_user.space_id,
      state: "CLOSED"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    %{
      "data" => %{
        "space" => %{
          "posts" => %{
            "edges" => edges
          }
        }
      }
    } = json_response(conn, 200)

    assert Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "I'm closed"
           end)

    refute Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "I'm open"
           end)
  end

  test "filtering author", %{conn: conn, space: space, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{space_user: another_user}} = create_space_member(space)
    {:ok, %{post: _authored_post}} = create_post(space_user, group, %{body: "I'm right"})
    {:ok, %{post: _non_authored_post}} = create_post(another_user, group, %{body: "I'm wrong"})

    variables = %{
      space_id: space_user.space_id,
      author: "tiff"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    %{
      "data" => %{
        "space" => %{
          "posts" => %{
            "edges" => edges
          }
        }
      }
    } = json_response(conn, 200)

    assert Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "I'm right"
           end)

    refute Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "I'm wrong"
           end)
  end

  test "filtering recipients", %{conn: conn, space: space, space_user: space_user} do
    {:ok, %{space_user: another_user}} = create_space_member(space, %{handle: "felix"})
    {:ok, %{post: _}} = create_global_post(space_user, %{body: "Hi @felix"})
    {:ok, %{post: _}} = create_global_post(another_user, %{body: "I'm wrong"})

    variables = %{
      space_id: space_user.space_id,
      recipients: ["tiff", "felix"]
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    %{
      "data" => %{
        "space" => %{
          "posts" => %{
            "edges" => edges
          }
        }
      }
    } = json_response(conn, 200)

    assert Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "Hi @felix"
           end)

    refute Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "I'm wrong"
           end)
  end

  test "filtering for private messages", %{conn: conn, space: space, space_user: space_user} do
    {:ok, %{space_user: _}} = create_space_member(space, %{handle: "felix"})
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{post: _}} = create_global_post(space_user, %{body: "@felix I'm a private message"})
    {:ok, %{post: _}} = create_post(space_user, group, %{body: "I'm a channel message"})

    variables = %{
      space_id: space_user.space_id,
      privacy: "DIRECT"
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    %{
      "data" => %{
        "space" => %{
          "posts" => %{
            "edges" => edges
          }
        }
      }
    } = json_response(conn, 200)

    assert Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "@felix I'm a private message"
           end)

    refute Enum.any?(edges, fn edge ->
             edge["node"]["body"] == "I'm a channel message"
           end)
  end
end
