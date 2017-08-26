defmodule BridgeWeb.Schema.InputObjects do
  @moduledoc """
  GraphQL input object definitions.
  """

  use Absinthe.Schema.Notation

  @desc "The field and direction to sort users."
  input_object :user_order do
    @desc "The field by which to sort users."
    field :field, non_null(:user_order_field)

    @desc "The sort direction."
    field :direction, non_null(:order_direction)
  end

  @desc "The field and direction to sort users."
  input_object :draft_order do
    @desc "The field by which to sort users."
    field :field, non_null(:draft_order_field)

    @desc "The sort direction."
    field :direction, non_null(:order_direction)
  end
end
