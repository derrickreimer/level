defmodule Sprinkle.Threads do
  @moduledoc """
  Threads are where all conversations take place. Recipients can include
  individual users as well as groups of users.
  """

  alias Sprinkle.Repo
  alias Sprinkle.Threads.Draft

  @doc """
  Build a changeset for creating a new draft.
  """
  def create_draft_changeset(params \\ %{}) do
    Draft.create_changeset(%Draft{}, params)
  end

  @doc """
  Create a new draft from a changeset.
  """
  def create_draft(%Ecto.Changeset{} = changeset) do
    Repo.insert(changeset)
  end

  @doc """
  Create a new draft from params.
  """
  def create_draft(user, params \\ %{}) do
    params
    |> Map.put(:user_id, user.id)
    |> Map.put(:team_id, user.team_id)
    |> create_draft_changeset()
    |> create_draft()
  end

  @doc """
  Fetches a draft by id and returns nil if not found.
  """
  def get_draft(id) do
    Repo.get(Draft, id)
  end

  @doc """
  Fetches a draft by id and returns nil if not found.
  """
  def get_draft_for_user(user, id) do
    Repo.get_by(Draft, %{id: id, user_id: user.id})
  end

  @doc """
  Build a changeset for updating a draft.
  """
  def update_draft_changeset(draft, params \\ %{}) do
    Draft.update_changeset(draft, params)
  end

  @doc """
  Updates a draft from a changeset.
  """
  def update_draft(%Ecto.Changeset{} = changeset) do
    Repo.update(changeset)
  end

  @doc """
  Updates a draft from params.
  """
  def update_draft(draft, params \\ %{}) do
    draft
    |> update_draft_changeset(params)
    |> update_draft()
  end

  @doc """
  Deletes a draft.
  """
  def delete_draft(draft) do
    Repo.delete(draft)
  end

  @doc """
  Generates the recipient ID for a resource able to be specified as a thread
  recipient.
  """
  def get_recipient_id(%Sprinkle.Teams.User{id: id}) do
    "u:#{id}"
  end
end
