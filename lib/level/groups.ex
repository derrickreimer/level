defmodule Level.Groups do
  @moduledoc """
  The Groups context.
  """

  import Ecto.Query, warn: false
  alias Level.Repo

  alias Level.Groups.Group

  @doc """
  Creates a group.

  ## Examples

      iex> create_group(%User{}, %{name: value})
      {:ok, %Group{}}

      iex> create_group(%User{}, %{name: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_group(creator, params \\ %{}) do
    params_with_relations =
      params
      |> Map.put(:space_id, creator.space_id)
      |> Map.put(:creator_id, creator.id)

    %Group{}
    |> Group.changeset(params_with_relations)
    |> Repo.insert()
  end
end
