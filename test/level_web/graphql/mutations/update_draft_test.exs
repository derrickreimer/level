defmodule LevelWeb.GraphQL.UpdateDraftTest do
  use LevelWeb.ConnCase
  import LevelWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)

    {:ok, draft} = insert_draft(space, user)

    {:ok, %{conn: conn, user: user, space: space, draft: draft}}
  end

  test "updates a draft when given valid data", %{conn: conn, draft: draft} do
    new_subject = "The new subject!"
    original_body = draft.body

    query = """
      mutation {
        updateDraft(id: "#{draft.id}", subject: "#{new_subject}") {
          success
          draft {
            subject
            body
          }
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
        "updateDraft" => %{
          "success" => true,
          "draft" => %{
            "subject" => new_subject,
            "body" => original_body
          },
          "errors" => []
        }
      }
    }
  end

  test "returns errors when draft does not belong to the authenticated user",
    %{conn: conn, space: space} do

    {:ok, %{user: other_user}} = insert_signup(%{space_id: space.id})
    {:ok, non_owned_draft} = insert_draft(space, other_user)

    query = """
      mutation {
        updateDraft(id: "#{non_owned_draft.id}", subject: "Trollin") {
          success
          draft {
            subject
          }
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
        "updateDraft" => %{
          "success" => false,
          "draft" => nil,
          "errors" => [
            %{"attribute" => "base", "message" => "Draft not found"}
          ]
        }
      }
    }
  end

  test "returns validation errors when data is invalid",
    %{conn: conn, draft: draft} do
    old_subject = draft.subject
    new_subject = String.duplicate("a", 260) # too long

    query = """
      mutation {
        updateDraft(id: "#{draft.id}", subject: "#{new_subject}") {
          success
          draft {
            subject
          }
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
        "updateDraft" => %{
          "success" => false,
          "draft" => %{
            "subject" => old_subject
          },
          "errors" => [
            %{"attribute" => "subject", "message" => "should be at most 255 character(s)"}
          ]
        }
      }
    }
  end
end
