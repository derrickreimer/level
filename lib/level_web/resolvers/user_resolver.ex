defmodule LevelWeb.UserResolver do
  @moduledoc """
  GraphQL query resolution for users.
  """

  alias Level.Rooms

  @doc """
  Fetches draft connection data based on the given query args.
  """
  def drafts(user, args, _info) do
    Level.Connections.drafts(user, args, %{})
  end

  @doc """
  Fetches room subscription connection data based on the given query args.
  """
  def room_subscriptions(user, args, _info) do
    Level.Connections.room_subscriptions(user, args, %{})
  end

  @doc """
  Fetches a room by id.
  """
  def room(user, args, _info) do
    Rooms.get_room(user, args[:id])
  end
end
