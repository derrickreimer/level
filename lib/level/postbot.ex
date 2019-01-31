defmodule Level.Postbot do
  @moduledoc """
  All things Postbot-related.
  """

  alias Ecto.Changeset
  alias Level.Repo
  alias Level.Schemas.Bot
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser
  alias Level.Spaces

  @doc """
  Creates the bot.
  """
  @spec create_bot!() :: Bot.t() | no_return()
  def create_bot!() do
    %Bot{}
    |> Changeset.change(%{state: "ACTIVE", display_name: "Postbot", handle: "postbot"})
    |> Repo.insert!(on_conflict: :nothing)
  end

  @doc """
  Fetches the bot.
  """
  @spec get_bot!() :: Bot.t() | no_return()
  def get_bot!() do
    Repo.get_by!(Bot, handle: "postbot")
  end

  @doc """
  Fetches the Level space bot for a given space.
  """
  @spec get_space_bot(Space.t() | SpaceUser.t()) :: SpaceBot.t() | no_return()
  def get_space_bot(%Space{id: space_id}), do: do_get_space_bot(space_id)
  def get_space_bot(%SpaceUser{space_id: space_id}), do: do_get_space_bot(space_id)

  defp do_get_space_bot(space_id) do
    Repo.get_by(SpaceBot, space_id: space_id, handle: "postbot")
  end

  @doc """
  Installs the bot in a space.
  """
  @spec install_bot(Space.t()) :: {:ok, SpaceBot.t()} | {:error, Ecto.Changeset.t()}
  def install_bot(%Space{} = space) do
    Spaces.install_bot(space, get_bot!())
  end
end
