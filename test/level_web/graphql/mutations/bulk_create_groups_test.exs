defmodule LevelWeb.GraphQL.BulkCreateGroupTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Groups

  @query """
    mutation BulkCreateGroups(
      $space_id: ID!,
      $names: [String]!
    ) {
      bulkCreateGroups(
        spaceId: $space_id,
        names: $names
      ) {
        payloads {
          success
          args {
            name
          }
          group {
            name
          }
          errors {
            attribute
            message
          }
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "creates a all the groups given valid data", %{conn: conn, space: space} do
    variables = %{
      space_id: space.id,
      names: ["Announcements", "Engineering"]
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "bulkCreateGroups" => %{
                 "payloads" => [
                   %{
                     "success" => true,
                     "args" => %{
                       "name" => "Announcements"
                     },
                     "group" => %{
                       "name" => "Announcements"
                     },
                     "errors" => []
                   },
                   %{
                     "success" => true,
                     "args" => %{
                       "name" => "Engineering"
                     },
                     "group" => %{
                       "name" => "Engineering"
                     },
                     "errors" => []
                   }
                 ]
               }
             }
           }
  end

  test "returns validation errors when data is invalid", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    Groups.create_group(space_user, %{name: "Announcements"})

    variables = %{
      space_id: space.id,
      names: ["Announcements", "Engineering"]
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "bulkCreateGroups" => %{
                 "payloads" => [
                   %{
                     "success" => false,
                     "args" => %{
                       "name" => "Announcements"
                     },
                     "group" => nil,
                     "errors" => [
                       %{"attribute" => "name", "message" => "has already been taken"}
                     ]
                   },
                   %{
                     "success" => true,
                     "args" => %{
                       "name" => "Engineering"
                     },
                     "group" => %{
                       "name" => "Engineering"
                     },
                     "errors" => []
                   }
                 ]
               }
             }
           }
  end
end
