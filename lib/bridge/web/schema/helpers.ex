defmodule Bridge.Web.Schema.Helpers do
  @moduledoc """
  GraphQL helper functions.
  """

  alias Bridge.Repo

  # Borrowed from http://absinthe-graphql.org/guides/ecto-best-practices/
  def by_id(model, ids) do
    import Ecto.Query
    model
    |> where([m], m.id in ^ids)
    |> Repo.all
    |> Map.new(&{&1.id, &1})
  end
end
