defmodule Bridge.Teams do
  @moduledoc """
  Teams are the fundamental organizational unit in Bridge. Think of a team like
  a "company" or "organization", just more concise and generically-named.

  All users must be related to a particular team, either as the the owner or
  some other role.
  """

  alias Bridge.Teams.Registration
  alias Bridge.Teams.Invitation
  alias Bridge.Repo

  @doc """
  Generates a changeset for performing user registration.
  """
  def registration_changeset(struct, params \\ %{}) do
    Registration.changeset(struct, params)
  end

  @doc """
  Performs user registration and team creation, given a changeset.
  """
  def register(changeset) do
    changeset
    |> Registration.transaction()
    |> Repo.transaction()
  end

  @doc """
  Generates a changeset for creating an invitation.
  """
  def create_invitation_changeset(params \\ %{}) do
    Invitation.changeset(%Invitation{}, params)
  end

  @doc """
  Creates an invitation and sends an email to the invited person.
  """
  def create_invitation(changeset) do
    case Repo.insert(changeset) do
      {:ok, invitation} ->
        invitation =
          invitation
          |> Repo.preload([:team, :invitor])

        invitation
        |> Bridge.Email.invitation_email()
        |> Bridge.Mailer.deliver_later()

        {:ok, invitation}

      error ->
        error
    end
  end
end
