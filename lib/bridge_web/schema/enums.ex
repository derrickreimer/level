defmodule BridgeWeb.Schema.Enums do
  @moduledoc """
  GraphQL enum type definitions.
  """

  use Absinthe.Schema.Notation

  @desc """
  The `UserState` enum type represents the possible states a `User` object
  can have.
  """
  enum :user_state do
    value :active,
      as: "ACTIVE",
      description: "The default state for a user."

    value :disabled,
      as: "DISABLED",
      description: """
      The state when a user's membership has been revoked or the user has
      opted-out of the team.
      """
  end

  @desc """
  The `UserRole` enum type represents the possible roles a `User` object
  can have.
  """
  enum :user_role do
    value :member,
      as: "MEMBER",
      description: "The default, lowest level permissions for a user."

    value :admin,
      as: "ADMIN",
      description: """
      Elevated permissions that allow the user to administrate the team,
      but not manage billing and other vital functions.
      """

    value :owner,
      as: "OWNER",
      description: "The highest level of permissions a user can have."
  end

  @desc """
  The `TeamState` scalar type represents the possible states a `Team` object
  can have.
  """
  enum :team_state do
    value :active,
      as: "ACTIVE",
      description: "The default state for a team."

    value :disabled,
      as: "DISABLED",
      description: "The state when a team has been shut down."
  end

  @desc """
  The `InvitationState` scalar type represents the possible states an
  `Invitation` object can have.
  """
  enum :invitation_state do
    value :pending,
      as: "PENDING",
      description: "The default state for an invitation."

    value :accepted,
      as: "ACCEPTED",
      description: "The state when the invitation has been accepted."

    value :revoked,
      as: "REVOKED",
      description: "The state when an invitation has been revoked."
  end
end
