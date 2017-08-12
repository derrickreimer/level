defmodule Bridge.Teams do
  alias Bridge.Teams.Registration
  alias Bridge.Repo

  def registration_changeset(struct, params \\ %{}) do
    Registration.changeset(struct, params)
  end

  def register(changeset) do
    changeset
    |> Registration.transaction()
    |> Repo.transaction()
  end
end
