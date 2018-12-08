defmodule Level.Digests.Options do
  @moduledoc """
  Options for generating a digest.
  """

  @enforce_keys [:title, :subject, :key, :start_at, :end_at, :now, :time_zone, :sections]
  defstruct [:title, :subject, :key, :start_at, :end_at, :now, :time_zone, :sections]

  @type t :: %__MODULE__{
          title: String.t(),
          subject: String.t(),
          key: String.t(),
          start_at: NaiveDateTime.t(),
          end_at: NaiveDateTime.t(),
          now: DateTime.t(),
          time_zone: String.t(),
          sections: [fun()]
        }
end
