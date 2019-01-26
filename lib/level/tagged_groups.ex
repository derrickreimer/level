defmodule Level.TaggedGroups do
  @moduledoc """
  The TaggedGroups context.
  """

  import Ecto.Query

  alias Level.Groups
  alias Level.Repo
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser

  @doc """
  The pattern for matching channels in a body of text.
  """
  def hashtag_pattern do
    ~r/
      (?:^|\W)                    # beginning of string or non-word char
      \#((?>[a-z0-9][a-z0-9-]*))  # hashtag
      (?!\/)                      # without a trailing slash
      (?=
        \.+[ \t\W]|               # dots followed by space or non-word character
        \.+$|                     # dots at end of line
        [^0-9a-zA-Z_.]|           # non-word character except dot
        $                         # end of line
      )
    /ix
  end

  @doc """
  Fetches all tagged groups from a body of text.
  """
  @spec get_tagged_groups(SpaceUser.t() | SpaceBot.t(), String.t()) :: [Group.t()]
  def get_tagged_groups(actor, text) do
    hashtag_pattern()
    |> Regex.scan(text, capture: :all_but_first)
    |> process_tags()
    |> fetch_groups(actor)
  end

  defp process_tags([], _) do
    []
  end

  defp process_tags(tags) do
    tags
    |> Enum.map(fn [tag] -> String.downcase(tag) end)
    |> Enum.uniq()
  end

  defp fetch_groups([], _) do
    []
  end

  defp fetch_groups(tags, actor) do
    query =
      actor
      |> Groups.groups_base_query()
      |> where([g], g.name in ^tags)

    Repo.all(query)
  end
end
