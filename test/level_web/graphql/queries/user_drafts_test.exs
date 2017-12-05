defmodule LevelWeb.GraphQL.UserDraftsTest do
  use LevelWeb.ConnCase
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Threads

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)
    {:ok, %{conn: conn, user: user, space: space}}
  end

  test "returns drafts belonging to the user",
    %{conn: conn, user: user, space: space} do
    query = """
      {
        viewer {
          drafts(first: 10) {
            edges {
              node {
                id
                subject
                user {
                  id
                }
              }
            }
            total_count
          }
        }
      }
    """

    params = valid_draft_params(%{space: space, user: user})
    changeset = Threads.create_draft_changeset(params)
    {:ok, draft} = Threads.create_draft(changeset)

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", query)

    assert json_response(conn, 200) == %{
      "data" => %{
        "viewer" => %{
          "drafts" => %{
            "edges" => [%{
              "node" => %{
                "id" => to_string(draft.id),
                "subject" => draft.subject,
                "user" => %{
                  "id" => to_string(user.id)
                }
              }
            }],
            "total_count" => 1
          }
        }
      }
    }
  end
end
