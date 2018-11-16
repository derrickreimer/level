defmodule Level.Digests.Digest do
  @moduledoc """
  A compiled digest.
  """

  alias Level.Digests.Section

  @enforce_keys [
    :id,
    :space_id,
    :space_slug,
    :space_name,
    :title,
    :subject,
    :to_email,
    :sections,
    :start_at,
    :end_at,
    :time_zone
  ]

  defstruct [
    :id,
    :space_id,
    :space_slug,
    :space_name,
    :title,
    :subject,
    :to_email,
    :sections,
    :start_at,
    :end_at,
    :time_zone
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          space_id: String.t(),
          space_slug: String.t(),
          space_name: String.t(),
          title: String.t(),
          subject: String.t(),
          to_email: String.t(),
          sections: [Section.t()],
          start_at: DateTime.t(),
          end_at: DateTime.t(),
          time_zone: String.t()
        }
end
