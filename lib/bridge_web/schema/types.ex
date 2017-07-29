defmodule BridgeWeb.Schema.Types do
  @moduledoc """
  GraphQL type definitions.
  """

  use Absinthe.Schema.Notation

  alias BridgeWeb.Schema.Helpers

  @desc """
  The `Time` scalar type represents time values provided in the ISOz
  datetime format (that is, the ISO 8601 format without the timezone offset, e.g.,
  "2015-06-24T04:50:34Z").
  """
  scalar :time, description: "ISOz time" do
    parse &Timex.parse(&1.value, "{ISO:Extended:Z}")
    serialize &Timex.format!(&1, "{ISO:Extended:Z}")
  end

  @desc """
  The `UserState` enum type represents the possible states a `User` object
  can have.
  """
  enum :user_state do
    value :active, as: "ACTIVE", description: "The default state for a user."
    value :disabled, as: "DISABLED", description: "The state when a user's membership has been revoked or the user has opted-out of the team."
  end

  @desc """
  The `UserRole` enum type represents the possible roles a `User` object
  can have.
  """
  enum :user_role do
    value :member, as: "MEMBER", description: "The default, lowest level permissions for a user."
    value :admin, as: "ADMIN", description: "Elevated permissions that allow the user to administrate the team, but not manage billing and other vital functions."
    value :owner, as: "OWNER", description: "The highest level of permissions a user can have."
  end

  @desc """
  The `TeamState` scalar type represents the possible states a `Team` object
  can have.
  """
  enum :team_state do
    value :active, as: "ACTIVE", description: "The default state for a team."
    value :disabled, as: "DISABLED", description: "The state when a team has been shut down."
  end

  @desc """
  The `InvitationState` scalar type represents the possible states a `Invitation` object
  can have.
  """
  enum :invitation_state do
    value :pending, as: "PENDING", description: "The default state for an invitation, before it has been accepted."
    value :accepted, as: "ACCEPTED", description: "The state when the invitation has been accepted."
    value :revoked, as: "REVOKED", description: "The state when an invitation has been revoked."
  end

  @desc "A `User` represents a person belonging to a specific `Team`."
  object :user do
    field :id, non_null(:id)
    field :state, non_null(:user_state)
    field :role, non_null(:user_role)
    field :email, non_null(:string)
    field :username, non_null(:string)
    field :first_name, :string
    field :last_name, :string
    field :time_zone, :string
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :team, non_null(:team) do
      resolve fn user, _, _ ->
        batch({Helpers, :by_id, Bridge.Team}, user.team_id, fn batch_results ->
          {:ok, Map.get(batch_results, user.team_id)}
        end)
      end
    end
  end

  @desc "A `Team` is the main organizational unit for a Bridge account."
  object :team do
    field :id, non_null(:id)
    field :state, non_null(:team_state)
    field :name, non_null(:string)
    field :slug, non_null(:string)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)
  end

  @desc "An `Invitation` is the means by which a new user joins an existing `Team`."
  object :invitation do
    field :id, non_null(:id)
    field :state, non_null(:invitation_state)
    field :invitor, non_null(:user)
    field :email, non_null(:string)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)
  end

  @desc "The response to inviting a user to a team."
  object :invite_user_payload do
    field :success, :boolean
    field :invitation, :invitation
    field :errors, list_of(:error)
  end

  @desc "A validation error."
  object :error do
    field :attribute, non_null(:string)
    field :message, non_null(:string)
  end
end
