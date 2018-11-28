defmodule Level.Nudges do
  @moduledoc """
  The Nudges context.
  """

  import Ecto.Query
  import Level.Gettext

  alias Ecto.Changeset
  alias Level.Repo
  alias Level.Schemas.Nudge
  alias Level.Schemas.SpaceUser

  @doc """
  Creates a nudge.
  """
  @spec create_nudge(SpaceUser.t(), map()) :: {:ok, Nudge.t()} | {:error, Changeset.t()}
  def create_nudge(%SpaceUser{} = space_user, params) do
    params_with_relations =
      Map.merge(params, %{
        space_id: space_user.space_id,
        space_user_id: space_user.id
      })

    %Nudge{}
    |> Nudge.create_changeset(params_with_relations)
    |> Repo.insert()
  end

  @doc """
  Gets nudges for a user.
  """
  @spec list_nudges(SpaceUser.t()) :: [Nudge.t()]
  def list_nudges(%SpaceUser{} = space_user) do
    space_user
    |> Ecto.assoc(:nudges)
    |> Repo.all()
  end

  @doc """
  Fetches a nudge by id.
  """
  @spec get_nudge(SpaceUser.t(), String.t()) :: {:ok, Nudge.t()} | {:error, String.t()}
  def get_nudge(%SpaceUser{} = space_user, id) do
    space_user
    |> Ecto.assoc(:nudges)
    |> where([n], n.id == ^id)
    |> Repo.one()
    |> after_fetch()
  end

  defp after_fetch(%Nudge{} = nudge) do
    {:ok, nudge}
  end

  defp after_fetch(_) do
    {:error, dgettext("errors", "Nudge not found")}
  end
end
