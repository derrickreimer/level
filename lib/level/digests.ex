defmodule Level.Digests do
  @moduledoc """
  The Digests context.
  """

  import Ecto.Query
  import Level.Gettext

  alias Level.Digests.Builder
  alias Level.Digests.Compiler
  alias Level.Digests.Digest
  alias Level.Digests.Options
  alias Level.Email
  alias Level.Mailer
  alias Level.Repo
  alias Level.Schemas
  alias Level.Schemas.SpaceUser

  @doc """
  Fetches a digest.
  """
  @spec get_digest(String.t(), String.t()) :: {:ok, Digest.t()} | {:error, String.t()}
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
    {:ok, Compiler.compile_digest(digest)}
  end

  defp after_get_digest(_), do: {:error, dgettext("errors", "Digest not found")}

  @doc """
  Builds a digest for the given user.
  """
  @spec build(SpaceUser.t(), Options.t()) :: {:ok, Digest.t()} | {:error, String.t()}
  def build(%SpaceUser{} = space_user, %Options{} = opts) do
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
end
