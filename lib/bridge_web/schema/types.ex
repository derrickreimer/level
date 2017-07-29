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
  The `UserState` scalar type represents the possible states a `User` object
  can have:

  - `ACTIVE` - the default state for a user.
  - `DISABLED` - the state when a user's membership has been revoked or the user
    has opted-out of the team.
  """
  scalar :user_state do
    parse &Bridge.User.parse_state(&1.value)
    serialize &(&1)
  end

  @desc """
  The `UserRole` scalar type represents the possible roles a `User` object
  can have:

  - `MEMBER` - the default, lowest level permissions for a user.
  - `ADMIN` - elevated permissions that allow the user to administrate the team,
    but not manage billing and other vital functions.
  - `OWNER` - the highest level of permissions as user can have.
  """
  scalar :user_role do
    parse &Bridge.User.parse_role(&1.value)
    serialize &(&1)
  end

  @desc """
  The `TeamState` scalar type represents the possible states a `Team` object
  can have:

  - `ACTIVE` - the default state for a team.
  - `DISABLED` - the state when a team has been shut down.
  """
  scalar :team_state do
    parse &Bridge.Team.parse_state(&1.value)
    serialize &(&1)
  end

  @desc """
  The `InvitationState` scalar type represents the possible states a `Invitation` object
  can have:

  - `PENDING` - the default state for an invitation, before it has been accepted.
  - `ACCEPTED` - the state when the invitation has been accepted.
  - `REVOKED` - the state when an invitation has been revoked.
  """
  scalar :invitation_state do
    parse &Bridge.Invitation.parse_state(&1.value)
    serialize &(&1)
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
