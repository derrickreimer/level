defmodule Bridge.Web.Schema do
  @moduledoc """
  GraphQL schema.
  """

  use Absinthe.Schema
  import_types Bridge.Web.Schema.Types

  query do
    field :viewer, :user do
      resolve fn _, %{context: %{current_user: current_user}} ->
        {:ok, current_user}
      end
    end
  end
end
