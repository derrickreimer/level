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

  @desc "The field and direction to sort reactions."
  input_object :reaction_order do
    @desc "The field by which to sort."
    field :field, non_null(:reaction_order_field)

    @desc "The sort direction."
    field :direction, non_null(:order_direction)
  end

  @desc "The field and direction to sort notifications."
  input_object :notification_order do
    @desc "The field by which to sort."
    field :field, non_null(:notification_order_field)

    @desc "The sort direction."
    field :direction, non_null(:order_direction)
  end

  @desc "Filtering criteria for post connections."
  input_object :post_filters do
    @desc """
    Filter by whether the post is being followed by the user. A user is considered
    to be "following" a post if they are explicitly subscribed to it, or if the
    post was created in a group that the user belongs to.
    """
    field :following_state, :following_state_filter, default_value: :all

    @desc """
    Filter by the different inbox states.
    """
    field :inbox_state, :inbox_state_filter, default_value: :all

    @desc """
    Filter by the different post states.
    """
    field :state, :post_state_filter, default_value: :all

    @desc """
    Filter by last activity.
    """
    field :last_activity, :last_activity_filter, default_value: :all
  end

  @desc "Filtering criteria for notification connections."
  input_object :notification_filters do
    field :state, :notification_state_filter, default_value: :all
  end
end
