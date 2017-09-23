defmodule SprinkleWeb.GraphQL.CreateDraftTest do
  use SprinkleWeb.ConnCase
  import SprinkleWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, team: team}} = insert_signup()
    conn = authenticate_with_jwt(conn, team, user)
    {:ok, %{conn: conn, user: user, team: team}}
  end

  test "creates a draft with valid data",
    %{conn: conn, team: team, user: user} do
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
            team {
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
            "team" => %{
              "name" => team.name
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
