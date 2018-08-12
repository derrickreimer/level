defmodule Level.DataloaderSource do
  @moduledoc """
  Behaviour for dataloader source modules.
  """

  @callback dataloader_data(map()) :: Dataloader.Source.t() | none()
  @callback dataloader_query(Ecto.Queryable.t(), map()) :: Ecto.Queryable.t() | none()
end
