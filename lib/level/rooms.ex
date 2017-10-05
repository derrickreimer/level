defmodule Level.Rooms do
  @moduledoc """
  A room is place for miscellaneous discussions to occur amongst a group of
  users. Unlike conversations, rooms are designed to be long-lasting threads
  for small disparate discussions.
  """

  alias Level.Repo
  alias Level.Rooms.Room

  @doc """
  Builds a changeset for creating a new room.
  """
  def create_room_changeset(user, params \\ %{}) do
    params_with_relations =
      params
      |> Map.put(:creator_id, user.id)
      |> Map.put(:space_id, user.space_id)

    Room.create_changeset(%Room{}, params_with_relations)
  end

  @doc """
  Creates a new room.
  """
  def create_room(user, params \\ %{}) do
    user
    |> create_room_changeset(params)
    |> Repo.insert()
  end
end
