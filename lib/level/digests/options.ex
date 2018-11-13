defmodule Level.Digests.Options do
  @moduledoc """
  Options for generating a digest.
  """

  @enforce_keys [:title, :key, :start_at, :end_at]
  defstruct [:title, :key, :start_at, :end_at]

  @type t :: %__MODULE__{
          title: String.t(),
          key: String.t(),
          start_at: NaiveDateTime.t(),
          end_at: NaiveDateTime.t()
        }
end
