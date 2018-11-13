defmodule Level.DailyDigest do
  @moduledoc """
  Functions for generating the daily digest email.
  """

  import Ecto.Query

  alias Level.DailyDigest.Result
  alias Level.Digests.Options
  alias Level.Schemas.Digest
  alias Level.Schemas.SpaceUser

  @doc """
  Fetches space user ids that are due to receive the daily digest
  at the time the query is run.
  """
  @spec due_query(integer()) :: Ecto.Query.t()
  def due_query(hour_of_day) do
    # Here's the query written SQL:
    #
    # SELECT * FROM (
    #   SELECT EXTRACT(HOUR FROM NOW() AT TIME ZONE u.time_zone) AS hour,
    #          concat('daily:', to_char(NOW() AT TIME ZONE u.time_zone, 'yyyy-mm-dd')) AS digest_key,
    #          su.*
    #   FROM space_users AS su
    #   INNER JOIN users AS u ON su.user_id = u.id
    # ) AS su2
    # LEFT OUTER JOIN digests AS d ON d.space_user_id = su2.id AND d.key = su2.digest_key
    # WHERE d.id IS NULL AND su2.hour >= ?;
    inner_query =
      from su in Result,
        join: u in assoc(su, :user),
        select: %{
          su
          | hour: fragment("EXTRACT(HOUR FROM NOW() AT TIME ZONE ?)", u.time_zone),
            digest_key:
              fragment(
                "concat('daily:', to_char(NOW() AT TIME ZONE ?, 'yyyy-mm-dd'))",
                u.time_zone
              )
        }

    from r in subquery(inner_query),
      left_join: d in Digest,
      on: d.space_user_id == r.id and d.key == r.digest_key,
      where: is_nil(d.id) and r.hour >= ^hour_of_day
  end

  @doc """
  Builds options to a pass to the digest generator.
  """
  @spec build_options(String.t(), DateTime.t()) :: {:ok, Options.t()} | {:error, term()}
  def build_options(key, end_at) do
    case Timex.shift(end_at, hours: -24) do
      {:error, term} ->
        {:error, term}

      start_at ->
        opts = %Options{
          title: "Your Daily Digest",
          key: key,
          start_at: start_at,
          end_at: end_at
        }

        {:ok, opts}
    end
  end
end
