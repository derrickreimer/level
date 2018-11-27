defmodule Level.Tutorials do
  @moduledoc """
  The Tutorials context.
  """

  alias Ecto.Changeset
  alias Level.Repo
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.Tutorial

  @doc """
  Updates the current step for a particular user.
  """
  @spec update_current_step(SpaceUser.t(), String.t(), integer()) ::
          {:ok, Tutorial.t()} | {:error, Changeset.t()}
  def update_current_step(%SpaceUser{} = space_user, key, step) do
    changeset =
      Changeset.change(%Tutorial{}, %{
        space_id: space_user.space_id,
        space_user_id: space_user.id,
        key: key,
        current_step: step
      })

    opts = [
      on_conflict: [set: [current_step: step]],
      conflict_target: [:space_user_id, :key]
    ]

    Repo.insert(changeset, opts)
  end

  @doc """
  Updates the completion state for a particular user.
  """
  @spec mark_as_complete(SpaceUser.t(), String.t()) ::
          {:ok, Tutorial.t()} | {:error, Changeset.t()}
  def mark_as_complete(%SpaceUser{} = space_user, key) do
    changeset =
      Changeset.change(%Tutorial{}, %{
        space_id: space_user.space_id,
        space_user_id: space_user.id,
        key: key,
        is_complete: true
      })

    opts = [
      on_conflict: [set: [is_complete: true]],
      conflict_target: [:space_user_id, :key]
    ]

    Repo.insert(changeset, opts)
  end

  @doc """
  Fetches a tutorial by key.
  """
  @spec get_tutorial(SpaceUser.t(), String.t()) :: {:ok, Tutorial.t()}
  def get_tutorial(%SpaceUser{id: space_user_id}, key) do
    Tutorial
    |> Repo.get_by(space_user_id: space_user_id, key: key)
    |> after_get_tutorial(space_user_id, key)
  end

  defp after_get_tutorial(%Tutorial{} = tutorial, _, _) do
    {:ok, tutorial}
  end

  defp after_get_tutorial(nil, space_user_id, key) do
    {:ok,
     %Tutorial{
       space_user_id: space_user_id,
       key: key,
       current_step: 1,
       is_complete: false
     }}
  end
end
