defmodule Bridge.Threads do
  @moduledoc """
  Threads are where all conversations take place. Recipients can include
  individual users as well as groups of users.
  """

  alias Bridge.Repo
  alias Bridge.Threads.Draft

  @doc """
  Build a changeset for creating a new draft.
  """
  def create_draft_changeset(params \\ %{}) do
    Draft.create_changeset(%Draft{}, params)
  end

  @doc """
  Create a new draft from a changeset.
  """
  def create_draft(changeset) do
    Repo.insert(changeset)
  end
end
