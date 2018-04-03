defmodule LevelWeb.Schema.InputObjects do
  @moduledoc false

  use Absinthe.Schema.Notation

  @desc "The field and direction to sort users."
  input_object :user_order do
    @desc "The field by which to sort."
    field :field, non_null(:user_order_field)

    @desc "The sort direction."
    field :direction, non_null(:order_direction)
  end

  @desc "The field and direction to sort invitations."
  input_object :invitation_order do
    @desc "The field by which to sort."
    field :field, non_null(:invitation_order_field)

    @desc "The sort direction."
    field :direction, non_null(:order_direction)
  end
end
