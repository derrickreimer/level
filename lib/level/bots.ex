defmodule Level.Bots do
  @moduledoc """
  The Bots context.
  """

  alias Ecto.Changeset
  alias Level.Repo
  alias Level.Schemas.Bot

  @doc """
  Creates the special Level bot.
  """
  def create_level_bot!() do
    %Bot{}
    |> Changeset.change(%{state: "ACTIVE", display_name: "Level", handle: "levelbot"})
    |> Repo.insert!(on_conflict: :nothing)
  end

  @doc """
  Fetches Level bot.
  """
  def get_level_bot!() do
    Repo.get_by!(Bot, handle: "levelbot")
  end
end
