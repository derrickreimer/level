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

  @desc "The field and direction to sort users."
  input_object :space_order do
    @desc "The field by which to sort."
    field :field, non_null(:space_order_field)

    @desc "The sort direction."
    field :direction, non_null(:order_direction)
  end

  @desc "The field and direction to sort space users."
  input_object :space_user_order do
    @desc "The field by which to sort."
    field :field, non_null(:space_user_order_field)

    @desc "The sort direction."
    field :direction, non_null(:order_direction)
  end

  @desc "The field and direction to sort groups."
  input_object :group_order do
    @desc "The field by which to sort."
    field :field, non_null(:group_order_field)

    @desc "The sort direction."
    field :direction, non_null(:order_direction)
  end

  @desc "The field and direction to sort posts."
  input_object :post_order do
    @desc "The field by which to sort."
    field :field, non_null(:post_order_field)

    @desc "The sort direction."
    field :direction, non_null(:order_direction)
  end

  @desc "The field and direction to sort replies."
  input_object :reply_order do
    @desc "The field by which to sort."
    field :field, non_null(:reply_order_field)

    @desc "The sort direction."
    field :direction, non_null(:order_direction)
  end
end
