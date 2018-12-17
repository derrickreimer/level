defmodule Level.DailyDigest do
  @moduledoc """
  Functions for generating the daily digest email.
  """

  import Ecto.Query

  alias Level.Digests
  alias Level.Digests.InboxSummary
  alias Level.Digests.Options
  alias Level.Digests.RecentActivity
  alias Level.Posts
  alias Level.Repo
  alias Level.Schemas.Digest
  alias Level.Schemas.DueDigest
  alias Level.Schemas.SpaceUser

  @doc """
  Builds options to a pass to the digest generator.
  """
  @spec digest_options(String.t(), DateTime.t(), String.t()) :: Options.t()
  def digest_options(key, end_at, time_zone) do
    %Options{
      title: "Your Daily Digest",
      subject: "Your Daily Digest",
      key: key,
      start_at: Timex.shift(end_at, hours: -24),
      end_at: end_at,
      time_zone: time_zone,
      sections: [&InboxSummary.build/3, &RecentActivity.build/3],
      now: DateTime.utc_now()
    }
  end

  @doc """
  Fetches space user ids that are due to receive the daily digest
  at the time the query is run.
  """
  @spec due_query(DateTime.t(), integer()) :: Ecto.Query.t()
  def due_query(now, hour_of_day \\ 16) do
    inner_query =
      from su in "space_users",
        join: u in "users",
        on: su.user_id == u.id,
        where: su.is_digest_enabled == true,
        where: su.state == "ACTIVE",
        select: %DueDigest{
          id: su.id,
          space_id: su.space_id,
          space_user_id: su.id,
          hour: fragment("EXTRACT(HOUR FROM ? AT TIME ZONE ?)", ^now, u.time_zone),
          digest_key:
            fragment(
              "concat('daily:', to_char(? AT TIME ZONE ?, 'yyyy-mm-dd'))",
              ^now,
              u.time_zone
            ),
          time_zone: u.time_zone
        }

    from r in subquery(inner_query),
      left_join: d in Digest,
      on: d.space_user_id == r.space_user_id and d.key == r.digest_key,
      where: is_nil(d.id) and r.hour >= ^hour_of_day,
      select: %DueDigest{
        id: fragment("?::text", r.id),
        space_id: fragment("?::text", r.space_id),
        space_user_id: fragment("?::text", r.space_user_id),
        hour: r.hour,
        digest_key: r.digest_key,
        time_zone: r.time_zone
      }
  end

  @doc """
  Builds and sends all due digests.
  """
  @spec build_and_send([DueDigest.t()], DateTime.t()) :: [
          {:ok, Digest.t()}
          | {:skip, DueDigest.t()}
          | {:error, DueDigest.t()}
        ]
  def build_and_send(results, now) do
    Enum.map(results, fn result ->
      space_user = Repo.get(SpaceUser, result.id)
      opts = digest_options(result.digest_key, now, result.time_zone)

      if send?(space_user, opts) do
        space_user
        |> Digests.build(opts)
        |> send_after_build(result)
      else
        {:skip, result}
      end
    end)
  end

  def send_after_build({:ok, digest}, _) do
    _ = Digests.send_email(digest)
    {:ok, digest}
  end

  def send_after_build(_, result) do
    {:error, result}
  end

  @doc """
  Fetches sendables and processes them.
  """
  @spec periodic_task(integer()) :: [
          {:ok, Digest.t()}
          | {:skip, DueDigest.t()}
          | {:error, DueDigest.t()}
        ]
  def periodic_task(hour_of_day \\ 16) do
    now = DateTime.utc_now()

    now
    |> due_query(hour_of_day)
    |> Repo.all()
    |> build_and_send(now)
  end

  @doc """
  Determines if the digest has enough interesting data to actually send.
  """
  @spec send?(SpaceUser.t(), Options.t()) :: boolean()
  def send?(space_user, opts) do
    InboxSummary.has_data?(space_user, opts) || RecentActivity.has_data?(space_user, opts)
  end
end
