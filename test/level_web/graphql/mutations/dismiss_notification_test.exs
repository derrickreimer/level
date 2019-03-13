defmodule LevelWeb.GraphQL.DismissNotificationTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Notifications
  alias Level.Schemas.Notification
  alias Level.Schemas.Post

  @query """
    mutation DismissNotification(
      $id: ID
    ) {
      dismissNotification(
        id: $id
      ) {
        success
        notification {
          __typename
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

  test "dismisses just the notification with the given id", %{
    conn: conn,
    space_user: space_user
  } do
    p1 = %Post{id: "abc"}
    {:ok, n1} = Notifications.record_post_created(space_user, p1)
    {:ok, n2} = Notifications.record_post_closed(space_user, p1, space_user)

    p2 = %Post{id: "def"}
    {:ok, n3} = Notifications.record_post_closed(space_user, p2, space_user)

    variables = %{
      id: n1.id
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "dismissNotification" => %{
                 "success" => true,
                 "notification" => %{
                   "__typename" => "PostCreatedNotification"
                 },
                 "errors" => []
               }
             }
           }

    n1 = Repo.get(Notification, n1.id)
    n2 = Repo.get(Notification, n2.id)
    n3 = Repo.get(Notification, n3.id)

    assert n1.state == "DISMISSED"
    assert n2.state == "UNDISMISSED"
    assert n3.state == "UNDISMISSED"
  end
end
