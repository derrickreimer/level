defmodule LevelWeb.GraphQL.DeleteDraftTest do
  use LevelWeb.ConnCase
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Threads

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)
    {:ok, %{conn: conn, user: user, space: space}}
  end

  test "deletes the draft returning true", %{conn: conn, space: space, user: user} do
    {:ok, draft} = insert_draft(space, user)

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

  test "returns errors if draft does not exist", %{conn: conn} do
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

  test "returns errors if draft does not belong to authenticated user",
    %{conn: conn, space: space} do

    {:ok, %{user: other_user}} = insert_signup(%{space: space})
    {:ok, draft} = insert_draft(space, other_user)

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
