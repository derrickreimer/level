defmodule Bridge.Invitation do
  @moduledoc """
  An Invitation is the means by which users are invited to join a Team.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Bridge.Web.Gettext

  alias Bridge.Repo

  schema "invitations" do
    field :state, :integer
    field :role, :integer
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
    # TODO: validate uniqueness of pending invitations
    # TODO: define state enum
    struct
    |> cast(params, [:invitor_id, :team_id, :email])
    |> validate_required([:email])
    |> validate_format(:email, Bridge.User.email_format, message: dgettext("errors", "is invalid"))
    |> put_change(:state, 0)
    |> put_change(:role, 0) # TODO: have the user specify this?
    |> put_change(:token, generate_token())
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
