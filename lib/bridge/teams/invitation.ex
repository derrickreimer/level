defmodule Bridge.Teams.Invitation do
  @moduledoc """
  An Invitation is the means by which users are invited to join a Team.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import BridgeWeb.Gettext

  alias Ecto.Multi
  alias Bridge.Repo
  alias Bridge.Teams.User

  # @states ["PENDING", "ACCEPTED", "REVOKED"]

  schema "invitations" do
    field :state, :string, read_after_writes: true # invitation_state
    field :role, :string, read_after_writes: true # user_role
    field :token, :binary_id # uuid
    field :email, :string

    belongs_to :team, Bridge.Teams.Team
    belongs_to :invitor, Bridge.Teams.User
    belongs_to :acceptor, Bridge.Teams.User

    timestamps()
  end

  @doc """
  Fetchs a valid, pending invitation by team and token. If the invitation is not
  found, raises an Ecto exception.
  """
  def fetch_pending!(team, token) do
    __MODULE__
    |> Repo.get_by!(team_id: team.id, state: "PENDING", token: token)
    |> Repo.preload([:team, :invitor])
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:invitor_id, :team_id, :email])
    |> validate_required([:email])
    |> validate_format(:email, Bridge.Teams.User.email_format, message: dgettext("errors", "is invalid"))
    |> put_change(:token, generate_token())
    |> unique_constraint(:email, name: :invitations_unique_pending_email,
        message: dgettext("errors", "already has an invitation"),
        validation: :uniqueness)
  end

  @doc """
  Builds a changeset to use when accepting an invitation.
  """
  def accept_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:acceptor_id, :state])
  end

  @doc """
  Registers a user and marks the given invitation as accepted.
  """
  def accept(invitation, params \\ %{}) do
    user_changeset =
      %User{}
      |> User.signup_changeset(params)
      |> put_change(:team_id, invitation.team_id)
      |> put_change(:role, invitation.role)

    Repo.transaction(
      Multi.new
      |> Multi.insert(:user, user_changeset)
      |> Multi.run(:invitation, fn %{user: user} ->
        invitation
        |> accept_changeset(%{acceptor_id: user.id, state: "ACCEPTED"})
        |> Repo.update
      end)
    )
  end

  defp generate_token do
    Ecto.UUID.generate()
  end
end

defimpl Phoenix.Param, for: Bridge.Teams.Invitation do
  def to_param(%{token: token}) do
    token
  end
end
