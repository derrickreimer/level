defmodule Bridge.Invitation do
  @moduledoc """
  An Invitation is the means by which users are invited to join a Team.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Bridge.Web.Gettext

  alias Ecto.Multi
  alias Bridge.Repo

  schema "invitations" do
    field :state, :string
    field :role, :string
    field :email, :string
    field :token, :string

    belongs_to :team, Bridge.Team
    belongs_to :invitor, Bridge.User
    belongs_to :acceptor, Bridge.User

    timestamps()
  end

  @doc """
  Create a new invitation and send the invitation email if successful.
  """
  def create(params) do
    case Repo.insert(changeset(%__MODULE__{}, params)) do
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

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:invitor_id, :team_id, :email])
    |> validate_required([:email])
    |> validate_format(:email, Bridge.User.email_format, message: dgettext("errors", "is invalid"))
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
  def accept(invitation, user_changeset) do
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
    String.replace(Ecto.UUID.generate(), "-", "")
  end
end

defimpl Phoenix.Param, for: Bridge.Invitation do
  def to_param(%{token: token}) do
    token
  end
end
