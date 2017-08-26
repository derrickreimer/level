defmodule BridgeWeb.GraphQL.DeleteDraftTest do
  use BridgeWeb.ConnCase
  import BridgeWeb.GraphQL.TestHelpers

  alias Bridge.Threads

  setup %{conn: conn} do
    {:ok, %{user: user, team: team}} = insert_signup()
    conn = authenticate_with_jwt(conn, team, user)
    {:ok, %{conn: conn, user: user, team: team}}
  end

  test "deletes the draft returning true", %{conn: conn, team: team, user: user} do
    params = valid_draft_params(%{team: team, user: user})
    changeset = Threads.create_draft_changeset(params)
    {:ok, draft} = Threads.create_draft(changeset)

    query = """
      mutation {
        deleteDraft(id: "#{draft.id}") {
          success
          errors {
            attribute
            message
          }
        }
      }
    """

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", query)

    assert json_response(conn, 200) == %{
      "data" => %{
        "deleteDraft" => %{
          "success" => true,
          "errors" => []
        }
      }
    }

    assert Threads.get_draft(draft.id) == nil
  end

  test "returns false if draft does not exist", %{conn: conn} do
    query = """
      mutation {
        deleteDraft(id: "9999") {
          success
          errors {
            attribute
            message
          }
        }
      }
    """

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", query)

    assert json_response(conn, 200) == %{
      "data" => %{
        "deleteDraft" => %{
          "success" => false,
          "errors" => [%{
            "attribute" => "base",
            "message" => "Draft not found"
          }]
        }
      }
    }
  end
end
