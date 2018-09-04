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
    field :field, non_null(:post_order_field), default_value: :posted_at

    @desc "The sort direction."
    field :direction, non_null(:order_direction), default_value: :desc
  end

  @desc "The field and direction to sort replies."
  input_object :reply_order do
    @desc "The field by which to sort."
    field :field, non_null(:reply_order_field)

    @desc "The sort direction."
    field :direction, non_null(:order_direction)
  end

  @desc "Filtering criteria for post connections."
  input_object :post_filters do
    @desc "Filter by whether the post has pings for the current user."
    field :pings, :ping_filter, default_value: :all

    @desc """
    Filter by whether the post is being watched by the user. "Watched"
    posts include those posted a group the user is subscribed to, or
    those that the user is explicity subscribed to.
    """
    field :watching, :watching_filter, default_value: :all

    @desc """
    Filter by the different inbox states.
    """
    field :inbox, :inbox_filter, default_value: :all
  end
end
