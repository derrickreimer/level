defmodule Level.DataloaderSource do
  @moduledoc """
  Behaviour for dataloader source modules.
  """

  @callback dataloader_data(map()) :: Dataloader.Source.t() | no_return()
  @callback dataloader_query(Ecto.Queryable.t(), map()) :: Ecto.Queryable.t() | no_return()
end
