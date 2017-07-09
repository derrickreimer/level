defmodule Bridge.Web.Schema do
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
