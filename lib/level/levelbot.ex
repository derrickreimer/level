defmodule Level.Levelbot do
  @moduledoc """
  All things Levelbot-related.
  """

  alias Ecto.Changeset
  alias Level.Repo
  alias Level.Schemas.Bot
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser

  @doc """
  Creates levelbot.
  """
  @spec create_bot!() :: Bot.t() | no_return()
  def create_bot!() do
    %Bot{}
    |> Changeset.change(%{state: "ACTIVE", display_name: "Level", handle: "levelbot"})
    |> Repo.insert!(on_conflict: :nothing)
  end

  @doc """
  Fetches levelbot.
  """
  @spec get_bot!() :: Bot.t() | no_return()
  def get_bot!() do
    Repo.get_by!(Bot, handle: "levelbot")
  end

  @doc """
  Fetches the Level space bot for a given space.
  """
  @spec get_space_bot!(Space.t() | SpaceUser.t()) :: SpaceBot.t() | no_return()
  def get_space_bot!(%Space{id: space_id}), do: do_get_space_bot!(space_id)
  def get_space_bot!(%SpaceUser{space_id: space_id}), do: do_get_space_bot!(space_id)

  defp do_get_space_bot!(space_id) do
    Repo.get_by!(SpaceBot, space_id: space_id, handle: "levelbot")
  end

  @doc """
  Installs the bot in a space.
  """
  @spec install_bot(Space.t()) :: {:ok, SpaceBot.t()} | {:error, Ecto.Changeset.t()}
  def install_bot(%Space{} = space) do
    bot = get_bot!()

    params = %{
      space_id: space.id,
      bot_id: bot.id,
      handle: bot.handle,
      display_name: bot.display_name,
      avatar: bot.avatar
    }

    %SpaceBot{}
    |> Changeset.change(params)
    |> Repo.insert()
  end
end
