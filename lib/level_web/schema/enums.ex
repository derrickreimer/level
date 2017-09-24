defmodule LevelWeb.Schema.Enums do
  @moduledoc """
  GraphQL enum type definitions.
  """

  use Absinthe.Schema.Notation

  @desc """
  The `UserState` enum type represents the possible states a `User` object
  can have.
  """
  enum :user_state do
    @desc "The default state for a user."
    value :active, as: "ACTIVE"

    @desc """
    The state when a user's membership has been revoked or the user has
    opted-out of the team.
    """
    value :disabled, as: "DISABLED"
  end

  @desc """
  The `UserRole` enum type represents the possible roles a `User` object
  can have.
  """
  enum :user_role do
    @desc "The default, lowest level permissions for a user."
    value :member, as: "MEMBER"

    @desc """
    Elevated permissions that allow the user to administrate the team,
    but not manage billing and other vital functions.
    """
    value :admin, as: "ADMIN"

    @desc "The highest level of permissions a user can have."
    value :owner, as: "OWNER"
  end

  @desc """
  The `TeamState` scalar type represents the possible states a `Team` object
  can have.
  """
  enum :team_state do
    @desc "The default state for a team."
    value :active, as: "ACTIVE"

    @desc "The state when a team has been shut down."
    value :disabled, as: "DISABLED"
  end

  @desc """
  The `InvitationState` scalar type represents the possible states an
  `Invitation` object can have.
  """
  enum :invitation_state do
    @desc "The default state for an invitation."
    value :pending, as: "PENDING"

    @desc "The state when the invitation has been accepted."
    value :accepted, as: "ACCEPTED"

    @desc "The state when an invitation has been revoked."
    value :revoked, as: "REVOKED"
  end

  @desc """
  The `UserOrderField` scalar type represents the possible fields by which
  users can be ordered.
  """
  enum :user_order_field do
    @desc "Order by the username field."
    value :username
  end

  @desc """
  The `DraftOrderField` scalar type represents the possible fields by which
  drafts can be ordered.
  """
  enum :draft_order_field do
    @desc "Order by the updated_at field."
    value :updated_at
  end

  @desc """
  The `OrderDirection` scalar type represents the direction by which nodes
  should be sorted in a connection.
  """
  enum :order_direction do
    @desc "Sort in ascending order."
    value :asc

    @desc "Sort in descending order."
    value :desc
  end
end
