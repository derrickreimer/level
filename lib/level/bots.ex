defmodule Level.Bots do
  @moduledoc """
  The Bots context.
  """

  alias Ecto.Changeset
  alias Level.Bot
  alias Level.Repo

  @doc """
  Creates the special Level bot.
  """
  def create_level_bot!() do
    %Bot{}
    |> Changeset.change(%{state: "ACTIVE", display_name: "Level", handle: "levelbot"})
    |> Repo.insert!()
  end
end
