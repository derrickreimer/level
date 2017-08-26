defmodule Bridge.Threads do
  @moduledoc """
  Threads are where all conversations take place. Recipients can include
  individual users as well as groups of users.
  """

  alias Bridge.Repo
  alias Bridge.Threads.Draft

  import Bridge.Gettext

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

  @doc """
  Fetches a draft by id and returns nil if not found.
  """
  def get_draft(id) do
    Repo.get(Draft, id)
  end

  @doc """
  Deletes a draft by id.
  """
  def delete_draft(id) do
    case get_draft(id) do
      nil ->
        {:error, dgettext("errors", "Draft not found")}
      draft ->
        case Repo.delete(draft) do
          {:error, _} ->
            {:error, dgettext("errors", "An unexpected error occurred")}
          success ->
            success
        end
    end
  end
end
