defmodule Level.Resolvers.SearchConnection do
  @moduledoc """
  A paginated connection for fetching search results.
  """

  import Ecto.Query

  alias Level.Posts
  alias Level.Repo
  alias Level.Schemas.SearchResult
  alias Level.Spaces
  alias Level.Spaces.Space

  defstruct page: 1,
            count: 20,
            query: nil

  @type t :: %__MODULE__{
          page: integer(),
          count: integer(),
          query: String.t() | nil
        }

  @typedoc "A struct containing page info for offset-based pagination results."
  @type offset_page_info :: %{has_previous_page: boolean(), has_next_page: boolean()}

  @typedoc "The pagination result value."
  @type result :: {:ok, %{page_info: offset_page_info(), nodes: [SearchResult.t()]}}

  @spec get(Space.t(), map(), map()) :: {:ok, result()} | {:error, String.t()}
  def get(%Space{} = space, args, %{context: %{current_user: user}}) do
    case Spaces.get_space_user(user, space) do
      {:ok, space_user} ->
        page = get_page(args)
        count = get_count(args)

        results =
          space_user
          |> build_query(args.query, count + 1, get_offset(args))
          |> Repo.all()

        payload = %{
          page_info: %{
            has_previous_page: page > 1,
            has_next_page: Enum.count(results) > count
          },
          nodes: Enum.take(results, count)
        }

        {:ok, payload}

      err ->
        err
    end
  end

  defp build_query(space_user, query, limit, offset_value) do
    space_user
    |> Posts.search_query(query)
    |> limit(^limit)
    |> offset(^offset_value)
  end

  defp get_page(%{page: page}) when is_integer(page) do
    page
  end

  defp get_page(_), do: 1

  defp get_count(%{count: count}) when is_integer(count) and count > 0 and count < 100 do
    count
  end

  defp get_count(_), do: 20

  defp get_offset(args) do
    page = get_page(args)
    count = get_count(args)
    (page - 1) * count
  end
end
