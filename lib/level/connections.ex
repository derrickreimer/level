defmodule Level.Connections do
  @moduledoc """
  A context for exposing connections between nodes.
  """

  @doc """
  Fetch users belonging to a space.

  ## Examples

      users(space, %{limit: 2})
      => {:ok, %Level.Pagination.Result{
        edges: [%User{...}],
        page_info: %PageInfo{...},
        total_count: 10
      }}
  """
  def users(space, args, context \\ %{}) do
    Level.Connections.Users.get(space, args, context)
  end

  @doc """
  Fetch drafts belonging to a user.

  ## Examples

      drafts(user, %{limit: 2})
      => {:ok, %Level.Pagination.Result{
        edges: [%Draft{...}],
        page_info: %PageInfo{...},
        total_count: 10
      }}
  """
  def drafts(user, args, context \\ %{}) do
    Level.Connections.Drafts.get(user, args, context)
  end

  @doc """
  Fetch room subscriptions belonging to a user.

  ## Examples

      room_subscriptions(user, %{limit: 2})
      => {:ok, %Level.Pagination.Result{
        edges: [%RoomSubscription{...}],
        page_info: %PageInfo{...},
        total_count: 10
      }}
  """
  def room_subscriptions(user, args, context \\ %{}) do
    Level.Connections.RoomSubscriptions.get(user, args, context)
  end

  @doc """
  Fetch messages for a room.

  ## Examples

      room_messages(room, %{limit: 2})
      => {:ok, %Level.Pagination.Result{
        edges: [%Rooms.Message{...}],
        page_info: %PageInfo{...},
        total_count: 10
      }}
  """
  def room_messages(room, args, context \\ %{}) do
    Level.Connections.RoomMessages.get(room, args, context)
  end
end
