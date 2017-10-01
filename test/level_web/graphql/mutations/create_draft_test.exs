defmodule LevelWeb.GraphQL.CreateDraftTest do
  use LevelWeb.ConnCase
  import LevelWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)
    {:ok, %{conn: conn, user: user, space: space}}
  end

  test "creates a draft with valid data",
    %{conn: conn, space: space, user: user} do
    subject = "Foo"
    body = "The body"

    query = """
      mutation {
        createDraft(recipientIds: [], subject: "#{subject}", body: "#{body}") {
          success
          draft {
            subject
            body
            recipientIds
            space {
              name
            }
            user {
              email
            }
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
        "createDraft" => %{
          "success" => true,
          "draft" => %{
            "subject" => subject,
            "body" => body,
            "recipientIds" => [],
            "space" => %{
              "name" => space.name
            },
            "user" => %{
              "email" => user.email
            }
          },
          "errors" => []
        }
      }
    }
  end

  test "returns validation errors when data is invalid", %{conn: conn} do
    subject = String.duplicate("a", 260) # too long

    query = """
      mutation {
        createDraft(recipientIds: [], subject: "#{subject}", body: "") {
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
        "createDraft" => %{
          "success" => false,
          "draft" => nil,
          "errors" => [
            %{"attribute" => "subject", "message" => "should be at most 255 character(s)"}
          ]
        }
      }
    }
  end
end
