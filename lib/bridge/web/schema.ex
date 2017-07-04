defmodule Bridge.Web.Schema do
  use Absinthe.Schema
  import_types Bridge.Web.Schema.Types

  # TODO: add root `viewer` corresponding to the currently authenticated user
  query do
    field :teams, list_of(:team) do
      resolve &Bridge.Web.TeamResolver.all/2
    end
  end
end
