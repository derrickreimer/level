defmodule Bridge.Threads.Draft do
  @moduledoc """
  A `Draft` is a thread that has not yet been sent.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "drafts" do
    field :recipient_ids, {:array, :string}, read_after_writes: true
    field :subject, :string, read_after_writes: true
    field :body, :string, read_after_writes: true
    field :is_truncated, :boolean, read_after_writes: true
    belongs_to :team, Bridge.Teams.Team
    belongs_to :user, Bridge.Teams.User

    timestamps()
  end

  @doc """
  Builds a changeset for creating a new draft.
  """
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:team_id, :user_id, :recipient_ids, :subject, :body])
    |> validate_required([:team_id, :user_id, :recipient_ids])
    |> apply_common_validations()
  end

  @doc """
  Builds a changeset for updating a draft.
  """
  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:recipient_ids, :subject, :body])
    |> apply_common_validations()
  end

  defp apply_common_validations(changeset) do
    changeset
    |> validate_length(:subject, max: 255)
  end
end
