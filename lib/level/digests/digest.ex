defmodule Level.Digests.Digest do
  @moduledoc """
  A compiled digest.
  """

  alias Level.Digests.Section
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @enforce_keys [
    :id,
    :space_user,
    :space,
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
    :space_user,
    :space,
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
          space_user: SpaceUser.t(),
          space: Space.t(),
          title: String.t(),
          subject: String.t(),
          to_email: String.t(),
          sections: [Section.t()],
          start_at: DateTime.t(),
          end_at: DateTime.t(),
          time_zone: String.t()
        }
end
