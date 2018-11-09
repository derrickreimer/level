defmodule Level.Digests.Digest do
  @moduledoc """
  A compiled digest.
  """

  alias Level.Digests.Section

  @enforce_keys [:id, :title, :subject, :to_email, :sections, :start_at, :end_at]
  defstruct [:id, :title, :subject, :to_email, :sections, :start_at, :end_at]

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          subject: String.t(),
          to_email: String.t(),
          sections: [Section.t()],
          start_at: DateTime.t(),
          end_at: DateTime.t()
        }
end
