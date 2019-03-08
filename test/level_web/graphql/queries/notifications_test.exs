defmodule LevelWeb.GraphQL.NotificationsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Notifications

  @query """
    query GetNotifications(
      $after: Timestamp,
      $first: Int
    ) {
      notifications(
        after: $after,
        first: $first
      ) {
        edges {
          node {
            __typename
            ... on PostCreatedNotification {
              id
            }
            ... on PostClosedNotification {
              id
            }
            ... on PostReopenedNotification {
              id
            }
            ... on ReplyCreatedNotification {
              id
            }
            ... on PostReactionCreatedNotification {
              id
            }
            ... on ReplyReactionCreatedNotification {
              id
            }
          }
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, user} = create_user()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user}}
  end

  test "users can list their notifications", %{conn: conn, user: user} do
    {:ok, %{space_user: space_user}} = create_space(user)
    {:ok, %{post: post}} = create_global_post(space_user)

    {:ok, notification} = Notifications.record_post_created(space_user, post)

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: %{first: 20}})

    %{"data" => %{"notifications" => %{"edges" => edges}}} = json_response(conn, 200)

    assert Enum.any?(edges, fn edge ->
             edge["node"]["id"] == notification.id
           end)
  end
end
