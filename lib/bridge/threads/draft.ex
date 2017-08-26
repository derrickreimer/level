defmodule Bridge.Threads.Draft do
  @moduledoc """
  A `Draft` is a thread that has not yet been sent.
  """

  use Ecto.Schema

  schema "drafts" do
    field :recipients, {:array, :string}, read_after_writes: true
    field :subject, :string
    field :body, :string
    field :is_truncated, :boolean, read_after_writes: true
    belongs_to :team, Bridge.Teams.Team
    belongs_to :user, Bridge.Teams.User

    timestamps()
  end
end
