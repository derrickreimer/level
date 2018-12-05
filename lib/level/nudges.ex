defmodule Level.Nudges do
  @moduledoc """
  The Nudges context.
  """

  import Ecto.Query
  import Level.Gettext

  alias Ecto.Changeset
  alias Level.Digests
  alias Level.Repo
  alias Level.Schemas.DueNudge
  alias Level.Schemas.Nudge
  alias Level.Schemas.SpaceUser

  @doc """
  Fetches nudges that are due to send.
  """
  @spec due_query(DateTime.t()) :: Ecto.Query.t()
  def due_query(now) do
    inner_query =
      from n in "nudges",
        inner_join: su in "space_users",
        on: su.id == n.space_user_id,
        inner_join: u in "users",
        on: u.id == su.user_id,
        select: %DueNudge{
          id: fragment("?::text", n.id),
          minute: n.minute,
          time_zone: u.time_zone,
          digest_key:
            fragment(
              "concat('nudge:', ?, ':', to_char(timezone(?, ?), 'yyyy-mm-dd'))",
              n.id,
              u.time_zone,
              ^now
            ),
          current_minute:
            fragment(
              "(date_part('hour', timezone(?, ?))::integer * 60) + date_part('minute', timezone(?, ?))::integer",
              u.time_zone,
              ^now,
              u.time_zone,
              ^now
            )
        }

    from n in subquery(inner_query),
      left_join: d in "digests",
      on: d.key == n.digest_key,
      where: n.current_minute >= n.minute,
      where: n.current_minute < fragment("LEAST(? + 30, 1440)", n.minute),
      where: is_nil(d.id)
  end

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

  @doc """
  Deletes a nudge.
  """
  @spec delete_nudge(Nudge.t()) :: {:ok, Nudge.t()} | {:error, Changeset.t()}
  def delete_nudge(%Nudge{} = nudge) do
    Repo.delete(nudge)
  end

  @doc """
  Builds digest options based on "due nudge" data.
  """
  @spec digest_options(DueNudge.t()) :: Digests.Options.t()
  def digest_options(due_nudge) do
    %Digests.Options{
      title: "Recent Activity",
      key: due_nudge.digest_key,
      start_at: DateTime.utc_now(),
      end_at: DateTime.utc_now(),
      time_zone: due_nudge.time_zone
    }
  end
end
