defmodule Level.DailyDigest do
  @moduledoc """
  Functions for generating the daily digest email.
  """

  import Ecto.Query

  alias Level.DailyDigest.Sendable
  alias Level.Digests
  alias Level.Digests.Options
  alias Level.Repo
  alias Level.Schemas.Digest
  alias Level.Schemas.SpaceUser

  @doc """
  Builds options to a pass to the digest generator.
  """
  @spec options_for(String.t(), DateTime.t(), String.t()) :: Options.t()
  def options_for(key, end_at, time_zone) do
    %Options{
      title: "Your Daily Digest",
      key: key,
      start_at: Timex.shift(end_at, hours: -24),
      end_at: end_at,
      time_zone: time_zone
    }
  end

  @doc """
  Fetches space user ids that are due to receive the daily digest
  at the time the query is run.
  """
  @spec sendable_query(DateTime.t(), integer()) :: Ecto.Query.t()
  def sendable_query(now, hour_of_day \\ 16) do
    inner_query =
      from su in Sendable,
        join: u in assoc(su, :user),
        where: su.is_digest_enabled == true,
        select: %{
          su
          | hour: fragment("EXTRACT(HOUR FROM ? AT TIME ZONE ?)", ^now, u.time_zone),
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
      on: d.space_user_id == r.id and d.key == r.digest_key,
      where: is_nil(d.id) and r.hour >= ^hour_of_day
  end

  @doc """
  Accepts a query for Sendable records and executes it.
  """
  @spec fetch_sendables(Ecto.Query.t()) :: [Sendable.t()]
  def fetch_sendables(query) do
    Repo.all(query)
  end

  @doc """
  Builds and sends all due digests.

  TODO: parallelize this with retries.
  """
  @spec build_and_send([Sendable.t()]) :: [{:ok, Digest.t()} | {:error, Sendable.t()}]
  def build_and_send(results) do
    now = DateTime.utc_now()

    Enum.map(results, fn result ->
      space_user = Repo.get(SpaceUser, result.id)
      opts = options_for(result.digest_key, now, result.time_zone)

      with {:ok, digest} <- Digests.build(space_user, opts),
           _ <- Digests.send_email(digest) do
        {:ok, digest}
      else
        _ ->
          {:error, result}
      end
    end)
  end

  @doc """
  Fetches sendables and processes them.
  """
  def periodic_task(hour_of_day \\ 16) do
    DateTime.utc_now()
    |> sendable_query(hour_of_day)
    |> fetch_sendables()
    |> build_and_send()
  end
end
