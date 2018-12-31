defmodule Level.Digests.Builder do
  @moduledoc false

  alias Ecto.Multi
  alias Level.Digests.Compiler
  alias Level.Digests.Options
  alias Level.Repo
  alias Level.Schemas
  alias Level.Schemas.SpaceUser

  def build(%SpaceUser{} = space_user, section_modules, %Options{} = opts) do
    space_user
    |> Repo.preload(:space)
    |> Repo.preload(:user)
    |> perform_build(section_modules, opts)
  end

  defp perform_build(space_user, section_modules, opts) do
    Multi.new()
    |> persist_digest(space_user.space, space_user, opts)
    |> persist_sections(space_user, section_modules, opts)
    |> Repo.transaction()
    |> after_build(space_user.space)
  end

  defp persist_digest(multi, space, space_user, opts) do
    subject = "[" <> space.name <> "] " <> opts.subject

    params = %{
      space_id: space_user.space_id,
      space_user_id: space_user.id,
      key: opts.key,
      title: opts.title,
      subject: subject,
      to_email: space_user.user.email,
      start_at: opts.start_at,
      end_at: opts.end_at,
      time_zone: opts.time_zone
    }

    changeset = Schemas.Digest.create_changeset(%Schemas.Digest{}, params)
    Multi.insert(multi, :digest, changeset)
  end

  defp persist_sections(multi, space_user, section_modules, opts) do
    Multi.run(multi, :sections, fn %{digest: digest} ->
      {:ok, reduce_sections(digest, space_user, section_modules, opts)}
    end)
  end

  defp reduce_sections(digest, space_user, section_modules, opts) do
    section_modules
    |> Enum.reduce([], fn section_module, sections ->
      case section_module.build(digest, space_user, opts) do
        {:ok, section} ->
          [section | sections]

        _ ->
          sections
      end
    end)
    |> Enum.reverse()
  end

  defp after_build({:ok, data}, space) do
    {:ok, Compiler.compile_digest(space, data.digest, data.sections)}
  end

  defp after_build(_, _) do
    {:error, "An unexpected error occurred"}
  end
end
