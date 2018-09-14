defmodule LevelWeb.GraphQL.RegisterPushSubscriptionTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Users
  alias Level.Users.User
  alias Level.WebPush.Subscription

  @query """
    mutation RegisterPushSubscription(
      $data: String
    ) {
      registerPushSubscription(
        data: $data
      ) {
        success
        errors {
          attribute
          message
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, user} = create_user()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user}}
  end

  test "registers push subscription data", %{conn: conn, user: %User{id: user_id}} do
    variables = %{data: valid_push_subscription_data("foo")}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "registerPushSubscription" => %{
                 "success" => true,
                 "errors" => []
               }
             }
           }

    assert %{^user_id => [%Subscription{endpoint: "foo"}]} =
             Users.get_push_subscriptions([user_id])
  end
end
