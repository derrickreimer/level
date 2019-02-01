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

  @desc "The response to updating a space."
  object :update_space_payload do
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

  @desc "The response to updating digest settings."
  object :update_digest_settings_payload do
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
    field :digest_settings, :digest_settings

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

  @desc "The response to closing a group."
  object :close_group_payload do
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

  @desc "The response to reopening a group."
  object :reopen_group_payload do
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

  @desc "The response to deleting a group."
  object :delete_group_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

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

  @desc "The response to subscribing to a group."
  object :subscribe_to_group_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The group.
    """
    field :group, :group

    interface :validatable
  end

  @desc "The response to watching a group."
  object :watch_group_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The group.
    """
    field :group, :group

    interface :validatable
  end

  @desc "The response to unsubscribing from a group."
  object :unsubscribe_from_group_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The group.
    """
    field :group, :group

    interface :validatable
  end

  @desc "The response to granting private access."
  object :grant_private_access_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    interface :validatable
  end

  @desc "The response to revoking private access."
  object :revoke_private_access_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

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
  object :create_post_payload do
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

  @desc "The response to updating a post."
  object :update_post_payload do
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

  @desc "The response to deleting a post."
  object :delete_post_payload do
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
  object :create_reply_payload do
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

  @desc "The response to updating a reply."
  object :update_reply_payload do
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

  @desc "The response to deleting a reply."
  object :delete_reply_payload do
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

  @desc "The response to recording a post view."
  object :record_post_view_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    interface :validatable
  end

  @desc "The response to dismissing a mention."
  object :dismiss_mentions_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The post for which mentions were dismissed. If the mutation was not successful,
    this field may be null.
    """
    field :posts, list_of(:post)

    interface :validatable
  end

  @desc "The response to dismissing posts."
  object :dismiss_posts_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The posts that were dismissed. If the mutation was not successful,
    this field may be null.
    """
    field :posts, list_of(:post)

    interface :validatable
  end

  @desc "The response to marking posts as unread."
  object :mark_as_unread_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The posts that were marked. If the mutation was not successful,
    this field may be null.
    """
    field :posts, list_of(:post)

    interface :validatable
  end

  @desc "The response to registering a push subscription."
  object :register_push_subscription_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    interface :validatable
  end

  @desc "The response to recording reply views."
  object :record_reply_views_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc "The replies marked as viewed."
    field :replies, list_of(:reply)

    interface :validatable
  end

  @desc "The response to closing a post."
  object :close_post_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc "The closed post."
    field :post, non_null(:post)

    interface :validatable
  end

  @desc "The response to reopening a post."
  object :reopen_post_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc "The reopened post."
    field :post, non_null(:post)

    interface :validatable
  end

  @desc "The response to creating group invitations."
  object :create_group_invitations_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc "The reopened post."
    field :invitees, list_of(non_null(:space_user))

    interface :validatable
  end

  @desc "The response to updating a tutorial current step."
  object :update_tutorial_step_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc "The tutorial."
    field :tutorial, :tutorial

    interface :validatable
  end

  @desc "The response to marking a tutorial as complete."
  object :mark_tutorial_complete_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc "The tutorial."
    field :tutorial, :tutorial

    interface :validatable
  end

  @desc "The response to creating a nudge."
  object :create_nudge_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc "The nudge."
    field :nudge, :nudge

    interface :validatable
  end

  @desc "The response to deleting a nudge."
  object :delete_nudge_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc "The nudge."
    field :nudge, :nudge

    interface :validatable
  end

  @desc "The response to revoking a user's space access."
  object :revoke_space_access_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc "The revoked space user."
    field :space_user, :space_user

    interface :validatable
  end

  @desc "The response to updating user's role."
  object :update_role_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc "The updated space user."
    field :space_user, :space_user

    interface :validatable
  end

  @desc "The response to creating a post reaction."
  object :create_post_reaction_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc "The post."
    field :post, :post

    @desc "The reaction."
    field :reaction, :post_reaction

    interface :validatable
  end

  @desc "The response to deleting a post reaction."
  object :delete_post_reaction_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc "The post."
    field :post, :post

    @desc "The reaction."
    field :reaction, :post_reaction

    interface :validatable
  end

  @desc "The response to creating a reply reaction."
  object :create_reply_reaction_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc "The reply."
    field :reply, :reply

    @desc "The reaction."
    field :reaction, :reply_reaction

    interface :validatable
  end

  @desc "The response to deleting a reply reaction."
  object :delete_reply_reaction_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, non_null(:boolean)

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc "The reply."
    field :reply, :reply

    @desc "The reaction."
    field :reaction, :reply_reaction

    interface :validatable
  end
end
