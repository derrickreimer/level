defmodule LevelWeb.GraphQL.BookmarkGroupTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Groups

  @bookmark_query """
    mutation BookmarkGroup(
      $space_id: ID!,
      $group_id: ID!
    ) {
      bookmarkGroup(
        spaceId: $space_id,
        groupId: $group_id
      ) {
        isBookmarked
        group {
          id
        }
      }
    }
  """

  @unbookmark_query """
    mutation UnbookmarkGroup(
      $space_id: ID!,
      $group_id: ID!
    ) {
      unbookmarkGroup(
        spaceId: $space_id,
        groupId: $group_id
      ) {
        isBookmarked
        group {
          id
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "bookmarks a group", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    :ok = Groups.unbookmark_group(group, space_user)
    variables = %{space_id: group.space_id, group_id: group.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @bookmark_query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "bookmarkGroup" => %{
                 "isBookmarked" => true,
                 "group" => %{
                   "id" => group.id
                 }
               }
             }
           }
  end

  test "unbookmarks a group", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    :ok = Groups.bookmark_group(group, space_user)
    variables = %{space_id: group.space_id, group_id: group.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @unbookmark_query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "unbookmarkGroup" => %{
                 "isBookmarked" => false,
                 "group" => %{
                   "id" => group.id
                 }
               }
             }
           }
  end
end
