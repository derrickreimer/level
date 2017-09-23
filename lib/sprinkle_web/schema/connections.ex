defmodule SprinkleWeb.Schema.Connections do
  @moduledoc """
  GraphQL type definitions for connections.
  """

  use Absinthe.Schema.Notation

  @desc "Data for pagination in a connection."
  object :page_info do
    @desc "The cursor correspodning to the first node."
    field :start_cursor, :cursor

    @desc "The cursor corresponding to the last node."
    field :end_cursor, :cursor

    @desc "A boolean indicating whether there are more items going forward."
    field :has_next_page, non_null(:boolean)

    @desc "A boolean indicating whether there are more items going backward."
    field :has_previous_page, non_null(:boolean)
  end

  @desc "An edge in the user connection."
  object :user_edge do
    @desc "The item at the edge of the node."
    field :node, :user

    @desc "A cursor for use in pagination."
    field :cursor, non_null(:cursor)
  end

  @desc "A list of users belonging to a team."
  object :user_connection do
    @desc "A list of edges."
    field :edges, list_of(:user_edge)

    @desc "Pagination data for the connection."
    field :page_info, non_null(:page_info)

    @desc "The total count of items in the connection."
    field :total_count, non_null(:integer)
  end

  @desc "An edge in the draft connection."
  object :draft_edge do
    @desc "The item at the edge of the node."
    field :node, :draft

    @desc "A cursor for use in pagination."
    field :cursor, non_null(:cursor)
  end

  @desc "A list of drafts belonging to a user."
  object :draft_connection do
    @desc "A list of edges."
    field :edges, list_of(:draft_edge)

    @desc "Pagination data for the connection."
    field :page_info, non_null(:page_info)

    @desc "The total count of items in the connection."
    field :total_count, non_null(:integer)
  end
end
