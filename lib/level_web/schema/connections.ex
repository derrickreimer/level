defmodule LevelWeb.Schema.Connections do
  @moduledoc false

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

  @desc "A list of users belonging to a space."
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

  @desc "An edge in the room subscription connection."
  object :room_subscription_edge do
    @desc "The item at the edge of the node."
    field :node, :room_subscription

    @desc "A cursor for use in pagination."
    field :cursor, non_null(:cursor)
  end

  @desc "A list of room subscriptions belonging to a user."
  object :room_subscription_connection do
    @desc "A list of edges."
    field :edges, list_of(:room_subscription_edge)

    @desc "Pagination data for the connection."
    field :page_info, non_null(:page_info)

    @desc "The total count of items in the connection."
    field :total_count, non_null(:integer)
  end

  @desc "An edge in the room message connection."
  object :room_message_edge do
    @desc "The item at the edge of the node."
    field :node, :room_message

    @desc "A cursor for use in pagination."
    field :cursor, non_null(:cursor)
  end

  @desc "A list of messages belonging to a room."
  object :room_message_connection do
    @desc "A list of edges."
    field :edges, list_of(:room_message_edge)

    @desc "Pagination data for the connection."
    field :page_info, non_null(:page_info)

    @desc "The total count of items in the connection."
    field :total_count, non_null(:integer)
  end

  @desc "An edge in the room user connection."
  object :room_user_edge do
    @desc "The item at the edge of the node."
    field :node, :user

    @desc "A cursor for use in pagination."
    field :cursor, non_null(:cursor)
  end

  @desc "A list of users in a room."
  object :room_user_connection do
    @desc "A list of edges."
    field :edges, list_of(:room_user_edge)

    @desc "Pagination data for the connection."
    field :page_info, non_null(:page_info)

    @desc "The total count of items in the connection."
    field :total_count, non_null(:integer)
  end

  @desc "An edge in the invitation connection."
  object :invitation_edge do
    @desc "The item at the edge of the node."
    field :node, :invitation

    @desc "A cursor for use in pagination."
    field :cursor, non_null(:cursor)
  end

  @desc "A list of invitations in a space."
  object :invitation_connection do
    @desc "A list of edges."
    field :edges, list_of(:invitation_edge)

    @desc "Pagination data for the connection."
    field :page_info, non_null(:page_info)

    @desc "The total count of items in the connection."
    field :total_count, non_null(:integer)
  end
end
