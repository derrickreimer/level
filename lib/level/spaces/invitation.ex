defmodule Level.Spaces.Invitation do
  @moduledoc """
  An Invitation is the means by which users are invited to join a Space.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Level.Gettext

  alias Ecto.Multi
  alias Level.Repo
  alias Level.Spaces.Space
  alias Level.Spaces.User
  alias Level.Rooms

  # @states ["PENDING", "ACCEPTED", "REVOKED"]

  schema "invitations" do
    field :state, :string, read_after_writes: true # invitation_state
    field :role, :string, read_after_writes: true # user_role
    field :token, :binary_id # uuid
    field :email, :string

    belongs_to :space, Space
    belongs_to :invitor, User
    belongs_to :acceptor, User

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:invitor_id, :space_id, :email])
    |> validate_required([:email])
    |> validate_format(:email, User.email_format, message: dgettext("errors", "is invalid"))
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
  Builds a transaction to execute when accepting an invitation.
  """
  def accept_transaction(invitation, params) do
    user_changeset =
      %User{}
      |> User.signup_changeset(params)
      |> put_change(:space_id, invitation.space_id)
      |> put_change(:role, invitation.role)

    Multi.new
    |> Multi.insert(:user, user_changeset)
    |> Multi.run(:invitation, fn %{user: user} ->
      invitation
      |> accept_changeset(%{acceptor_id: user.id, state: "ACCEPTED"})
      |> Repo.update()
    end)
    |> Multi.run(:room_subscriptions, fn %{user: user} ->
      {:ok, Rooms.subscribe_to_mandatory_rooms(user)}
    end)
  end

  defp generate_token do
    Ecto.UUID.generate()
  end
end

defimpl Phoenix.Param, for: Level.Spaces.Invitation do
  def to_param(%{token: token}) do
    token
  end
end
