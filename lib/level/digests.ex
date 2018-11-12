defmodule Level.Digests do
  @moduledoc """
  The Digests context.
  """

  import Ecto.Query
  import Level.Gettext

  alias Level.Digests.Builder
  alias Level.Digests.Compiler
  alias Level.Digests.Digest
  alias Level.Email
  alias Level.Mailer
  alias Level.Repo
  alias Level.Schemas
  alias Level.Schemas.SpaceUser

  @typedoc "An Olsen time zone"
  @type time_zone :: String.t()

  @typedoc "Options for building a digest"
  @type opts :: %{
          title: String.t(),
          start_at: NaiveDateTime.t(),
          end_at: NaiveDateTime.t()
        }

  @doc """
  Fetches a digest.
  """
  def get_digest(space_id, digest_id) do
    query =
      from d in Schemas.Digest,
        where: d.space_id == ^space_id and d.id == ^digest_id,
        preload: [digest_sections: [digest_posts: :post]]

    query
    |> Repo.one()
    |> after_get_digest()
  end

  defp after_get_digest(%Schemas.Digest{} = digest) do
    compiled_sections = Compiler.compile_sections(digest.digest_sections)
    compiled_digest = Compiler.compile_digest(digest, compiled_sections)
    {:ok, compiled_digest}
  end

  defp after_get_digest(_), do: {:error, dgettext("errors", "Digest not found")}

  @doc """
  Builds options for the daily digest.
  """
  @spec daily_opts(DateTime.t()) :: {:ok, opts()} | {:error, term()}
  def daily_opts(end_at) do
    case Timex.shift(end_at, hours: -24) do
      {:error, term} ->
        {:error, term}

      start_at ->
        opts = %{
          title: "Your Daily Digest",
          start_at: start_at,
          end_at: end_at
        }

        {:ok, opts}
    end
  end

  @doc """
  Builds a digest for the given user.
  """
  @spec build(SpaceUser.t(), opts()) :: {:ok, Digest.t()} | {:error, String.t()}
  def build(%SpaceUser{} = space_user, opts) do
    Builder.build(space_user, opts)
  end

  @doc """
  Sends a compiled digest email.
  """
  def send_email(%Digest{} = digest) do
    digest
    |> Email.digest()
    |> Mailer.deliver_now()
  end

  @doc """
  Builds and sends digests that are due.
  """
  def build_and_send do
    # TODO
  end
end
