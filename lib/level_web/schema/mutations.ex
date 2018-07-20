defmodule LevelWeb.Schema.Mutations do
  @moduledoc false

  use Absinthe.Schema.Notation

  @desc "Interface for payloads containing validation data."
  interface :validatable do
    field :success, non_null(:boolean)
    field :errors, list_of(:error)
    resolve_type fn _, _ -> nil end
  end

  @desc "A validation error."
  object :error do
    @desc "The name of the invalid attribute."
    field :attribute, non_null(:string)

    @desc "A human-friendly error message."
    field :message, non_null(:string)
  end

  @desc "The response to updating a user."
  object :update_user_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The mutated object. If the mutation was not successful,
    this field may be null.
    """
    field :user, :user

    interface :validatable
  end

  @desc "The response to creating a space."
  object :create_space_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The mutated object. If the mutation was not successful,
    this field may be null.
    """
    field :space, :space

    interface :validatable
  end

  @desc "The response to completing a setup step."
  object :complete_setup_step_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc """
    The next state.
    """
    field :state, :space_setup_state
  end

  @desc "The response to creating a group."
  object :create_group_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The mutated object. If the mutation was not successful,
    this field may be null.
    """
    field :group, :group

    interface :validatable
  end

  @desc "The response to updating a group."
  object :update_group_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The mutated object. If the mutation was not successful,
    this field may be null.
    """
    field :group, :group

    interface :validatable
  end

  @desc "The response to bulk creating groups."
  object :bulk_create_groups_payload do
    @desc "A list of result payloads for each group."
    field :payloads, non_null(list_of(:bulk_create_group_payload))
  end

  @desc "The payload for an individual group in a bulk create payload."
  object :bulk_create_group_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The mutated object. If the mutation was not successful,
    this field may be null.
    """
    field :group, :group

    @desc "The original arguments for this particular object."
    field :args, non_null(:bulk_create_group_args)

    interface :validatable
  end

  @desc "The arguments for an individual bulk-created group."
  object :bulk_create_group_args do
    @desc "The name of the group."
    field :name, non_null(:string)
  end

  @desc "The response to updating a group."
  object :update_group_membership_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The mutated object. If the mutation was not successful,
    this field may be null.
    """
    field :membership, non_null(:group_membership)

    interface :validatable
  end

  @desc "The payload for an updating group bookmark state."
  object :bookmark_group_payload do
    @desc "The current bookmark status."
    field :is_bookmarked, non_null(:boolean)

    @desc "The group."
    field :group, non_null(:group)
  end

  @desc "The response to posting a message to a group."
  object :post_to_group_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The mutated object. If the mutation was not successful,
    this field may be null.
    """
    field :post, :post

    interface :validatable
  end

  @desc "The response to replying to a post."
  object :reply_to_post_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The mutated object. If the mutation was not successful,
    this field may be null.
    """
    field :reply, :reply

    interface :validatable
  end
end
