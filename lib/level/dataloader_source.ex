defmodule Level.DataloaderSource do
  @moduledoc """
  Behaviour for dataloader source modules.
  """

  @callback dataloader_data(params :: map()) :: Dataloader.Source.t() | no_return()
  @callback dataloader_query(queryable :: Ecto.Queryable.t(), params :: map()) ::
              Ecto.Queryable.t() | no_return()
end
