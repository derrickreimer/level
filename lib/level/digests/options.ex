defmodule Level.Digests.Options do
  @moduledoc """
  Options for generating a digest.
  """

  @enforce_keys [:title, :key, :start_at, :end_at, :time_zone]
  defstruct [:title, :key, :start_at, :end_at, :time_zone]

  @type t :: %__MODULE__{
          title: String.t(),
          key: String.t(),
          start_at: NaiveDateTime.t(),
          end_at: NaiveDateTime.t(),
          time_zone: String.t()
        }
end
