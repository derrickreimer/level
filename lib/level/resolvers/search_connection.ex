defmodule Level.Resolvers.SearchConnection do
  @moduledoc """
  A paginated connection for fetching search results.
  """

  alias Level.Posts
  alias Level.Repo
  alias Level.Schemas.SearchResult
  alias Level.Schemas.Space
  alias Level.Spaces

  defstruct limit: 20,
            cursor: nil,
            query: nil

  @type t :: %__MODULE__{
          limit: integer(),
          cursor: DateTime.t() | nil,
          query: String.t() | nil
        }

  @spec get(Space.t(), map(), map()) :: {:ok, [SearchResult.t()]} | {:error, String.t()}
  def get(%Space{} = space, args, %{context: %{current_user: user}}) do
    case Spaces.get_space_user(user, space) do
      {:ok, space_user} ->
        args = prepare_args(args)

        results =
          space_user
          |> build_query(args)
          |> Repo.all()

        {:ok, results}

      err ->
        err
    end
  end

  defp prepare_args(args) do
    args
    |> Map.put(:limit, get_limit(args))
  end

  defp build_query(space_user, %{query: query, limit: limit, cursor: cursor}) do
    Posts.search_query(space_user, query, limit, cursor)
  end

  defp build_query(space_user, %{query: query, limit: limit}) do
    Posts.search_query(space_user, query, limit, nil)
  end

  defp get_limit(%{limit: limit}) when is_integer(limit) and limit > 0 and limit < 100 do
    limit
  end

  defp get_limit(_), do: 20
end
