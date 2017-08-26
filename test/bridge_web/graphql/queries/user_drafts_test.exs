defmodule BridgeWeb.GraphQL.UserDraftsTest do
  use BridgeWeb.ConnCase
  import BridgeWeb.GraphQL.TestHelpers

  alias Bridge.Threads

  setup %{conn: conn} do
    {:ok, %{user: user, team: team}} = insert_signup()
    conn = authenticate_with_jwt(conn, team, user)
    {:ok, %{conn: conn, user: user, team: team}}
  end

  test "returns drafts belonging to the user",
    %{conn: conn, user: user, team: team} do
    query = """
      {
        viewer {
          drafts(first: 10) {
            edges {
              node {
                id
                subject
              }
            }
            total_count
          }
        }
      }
    """

    params = valid_draft_params(%{team: team, user: user})
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
                "subject" => draft.subject
              }
            }],
            "total_count" => 1
          }
        }
      }
    }
  end
end
