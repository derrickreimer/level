defmodule Level.Connections do
  @moduledoc """
  A context for exposing connections between nodes.
  """

  @doc """
  Fetch users belonging to a space.

  ## Examples

      users(space, args)
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

      drafts(user, args)
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

      room_subscriptions(user, args)
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

      room_messages(room, args)
      => {:ok, %Level.Pagination.Result{
        edges: [%Rooms.Message{...}],
        page_info: %PageInfo{...},
        total_count: 10
      }}
  """
  def room_messages(room, args, context \\ %{}) do
    Level.Connections.RoomMessages.get(room, args, context)
  end

  @doc """
  Fetch users in a room.

  ## Examples

      room_users(room, args)
      => {:ok, %Level.Pagination.Result{
        edges: [%Spaces.User{...}],
        page_info: %PageInfo{...},
        total_count: 10
      }}
  """
  def room_users(room, args, context \\ %{}) do
    Level.Connections.RoomUsers.get(room, args, context)
  end
end
