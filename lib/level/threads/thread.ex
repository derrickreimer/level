defmodule Level.Threads.Thread do
  @moduledoc """
  A `Thread` represents a conversation between one or more `User` records
  (either directly, or via membership in a group).
  """

  use Ecto.Schema
  # import Ecto.Changeset

  # @states ["DRAFT", "SENT", "DELETED"]

  schema "threads" do
    field :state, :string, read_after_writes: true # team_state
    field :subject, :string
    belongs_to :team, Level.Teams.Team
    belongs_to :creator, Level.Teams.User

    timestamps()
  end
end
