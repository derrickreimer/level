defmodule LevelWeb.Schema.Enums do
  @moduledoc false

  use Absinthe.Schema.Notation

  enum :user_state do
    value(:active, as: "ACTIVE")
    value(:disabled, as: "DISABLED")
  end

  enum :user_role do
    value(:member, as: "MEMBER")
    value(:admin, as: "ADMIN")
    value(:owner, as: "OWNER")
  end

  enum :space_state do
    value(:active, as: "ACTIVE")
    value(:disabled, as: "DISABLED")
  end

  enum :invitation_state do
    value(:pending, as: "PENDING")
    value(:accepted, as: "ACCEPTED")
    value(:revoked, as: "REVOKED")
  end

  enum :post_state do
    value(:open, as: "OPEN")
    value(:closed, as: "CLOSED")
  end

  enum :user_order_field do
    value(:last_name)
  end

  enum :invitation_order_field do
    value(:email)
  end

  enum :group_order_field do
    value(:name)
  end

  enum :order_direction do
    value(:asc)
    value(:desc)
  end

  enum :group_state do
    value(:open, as: "OPEN")
    value(:closed, as: "CLOSED")
  end
end
