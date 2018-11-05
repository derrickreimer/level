defmodule LevelWeb.Schema do
  @moduledoc false

  use Absinthe.Schema

  alias Level.Groups
  alias Level.Posts
  alias Level.Spaces

  import Level.Gettext

  import_types LevelWeb.Schema.Objects
  import_types LevelWeb.Schema.Connections
  import_types LevelWeb.Schema.Mutations
  import_types LevelWeb.Schema.Subscriptions

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  query do
    @desc "The currently authenticated user."
    field :viewer, :user do
      resolve(fn _, %{context: %{current_user: current_user}} ->
        {:ok, current_user}
      end)
    end

    @desc "Fetches a space membership by space id."
    field :space_user, :space_user do
      arg :space_id, :id
      arg :space_slug, :string
      resolve &Level.Resolvers.space_user/2
    end

    @desc "Fetches a space."
    field :space, :space do
      arg :id, :id
      arg :slug, :string
      resolve &Level.Resolvers.space/2
    end

    @desc "Fetches a group."
    field :group, :group do
      arg :id, non_null(:id)
      resolve &Level.Resolvers.group/2
    end

    @desc "Fetches a space user by space and user id."
    field :space_user_by_user_id, :space_user do
      arg :space_id, non_null(:id)
      arg :user_id, non_null(:id)
      resolve &Level.Resolvers.space_user_by_user_id/2
    end
  end

  mutation do
    @desc "Update user settings."
    field :update_user, type: :update_user_payload do
      arg :first_name, :string
      arg :last_name, :string
      arg :handle, :string
      arg :email, :string

      resolve &Level.Mutations.update_user/2
    end

    @desc "Update the logged-in user's avatar."
    field :update_user_avatar, type: :update_user_payload do
      arg :data, non_null(:string)

      resolve &Level.Mutations.update_user_avatar/2
    end

    @desc "Create a space."
    field :create_space, type: :create_space_payload do
      arg :name, non_null(:string)
      arg :slug, non_null(:string)

      resolve &Level.Mutations.create_space/2
    end

    @desc "Update a space."
    field :update_space, type: :update_space_payload do
      arg :space_id, non_null(:id)
      arg :name, :string
      arg :slug, :string

      resolve &Level.Mutations.update_space/2
    end

    @desc "Updates a space's avatar."
    field :update_space_avatar, type: :update_space_payload do
      arg :space_id, non_null(:id)
      arg :data, non_null(:string)

      resolve &Level.Mutations.update_space_avatar/2
    end

    @desc "Mark a space setup step as complete."
    field :complete_setup_step, type: :complete_setup_step_payload do
      arg :space_id, non_null(:id)
      arg :state, non_null(:space_setup_state)
      arg :is_skipped, non_null(:boolean)

      resolve &Level.Mutations.complete_setup_step/2
    end

    @desc "Create a group."
    field :create_group, type: :create_group_payload do
      arg :space_id, non_null(:id)
      arg :name, non_null(:string)
      arg :description, :string
      arg :is_private, :boolean, default_value: false
      arg :is_default, :boolean, default_value: false

      resolve &Level.Mutations.create_group/2
    end

    @desc "Create multiple groups."
    field :bulk_create_groups, type: :bulk_create_groups_payload do
      arg :space_id, non_null(:id)
      arg :names, non_null(list_of(:string))

      resolve &Level.Mutations.bulk_create_groups/2
    end

    @desc "Update a group."
    field :update_group, type: :update_group_payload do
      arg :space_id, non_null(:id)
      arg :group_id, non_null(:id)
      arg :name, :string
      arg :description, :string
      arg :is_private, :boolean
      arg :is_default, :boolean

      resolve &Level.Mutations.update_group/2
    end

    @desc "Closes a group."
    field :close_group, type: :close_group_payload do
      arg :space_id, non_null(:id)
      arg :group_id, non_null(:id)

      resolve &Level.Mutations.close_group/2
    end

    @desc "Reopens a group."
    field :reopen_group, type: :reopen_group_payload do
      arg :space_id, non_null(:id)
      arg :group_id, non_null(:id)

      resolve &Level.Mutations.reopen_group/2
    end

    @desc "Deletes a group."
    field :delete_group, type: :delete_group_payload do
      arg :space_id, non_null(:id)
      arg :group_id, non_null(:id)

      resolve &Level.Mutations.delete_group/2
    end

    @desc "Subscribes to a group."
    field :subscribe_to_group, type: :subscribe_to_group_payload do
      arg :space_id, non_null(:id)
      arg :group_id, non_null(:id)

      resolve &Level.Mutations.subscribe_to_group/2
    end

    @desc "Unsubscribe from group."
    field :unsubscribe_from_group, type: :unsubscribe_from_group_payload do
      arg :space_id, non_null(:id)
      arg :group_id, non_null(:id)

      resolve &Level.Mutations.unsubscribe_from_group/2
    end

    @desc "Grant group access to a user."
    field :grant_group_access, type: :grant_group_access_payload do
      arg :space_id, non_null(:id)
      arg :group_id, non_null(:id)
      arg :space_user_id, non_null(:id)

      resolve &Level.Mutations.grant_group_access/2
    end

    @desc "Revoke group access from a user."
    field :revoke_group_access, type: :revoke_group_access_payload do
      arg :space_id, non_null(:id)
      arg :group_id, non_null(:id)
      arg :space_user_id, non_null(:id)

      resolve &Level.Mutations.revoke_group_access/2
    end

    @desc "Bookmark a group."
    field :bookmark_group, type: :bookmark_group_payload do
      arg :space_id, non_null(:id)
      arg :group_id, non_null(:id)

      resolve &Level.Mutations.bookmark_group/2
    end

    @desc "Unbookmark a group."
    field :unbookmark_group, type: :bookmark_group_payload do
      arg :space_id, non_null(:id)
      arg :group_id, non_null(:id)

      resolve &Level.Mutations.unbookmark_group/2
    end

    @desc "Posts a message to a group."
    field :create_post, type: :create_post_payload do
      arg :space_id, non_null(:id)
      arg :group_id, non_null(:id)
      arg :body, non_null(:string)
      arg :file_ids, list_of(:id)

      resolve &Level.Mutations.create_post/2
    end

    @desc "Updates a post."
    field :update_post, type: :update_post_payload do
      arg :space_id, non_null(:id)
      arg :post_id, non_null(:id)
      arg :body, :string

      resolve &Level.Mutations.update_post/2
    end

    @desc "Replies to a post."
    field :create_reply, type: :create_reply_payload do
      arg :space_id, non_null(:id)
      arg :post_id, non_null(:id)
      arg :body, non_null(:string)
      arg :file_ids, list_of(:id)

      resolve &Level.Mutations.create_reply/2
    end

    @desc "Updates a reply."
    field :update_reply, type: :update_reply_payload do
      arg :space_id, non_null(:id)
      arg :reply_id, non_null(:id)
      arg :body, :string

      resolve &Level.Mutations.update_reply/2
    end

    @desc "Records when a user views a post (optionally with the last viewed reply)."
    field :record_post_view, type: :record_post_view_payload do
      arg :space_id, non_null(:id)
      arg :post_id, non_null(:id)
      arg :last_viewed_reply_id, :id

      resolve &Level.Mutations.record_post_view/2
    end

    @desc "Dismisses mentions from the current user's inbox."
    field :dismiss_mentions, type: :dismiss_mentions_payload do
      arg :space_id, non_null(:id)
      arg :post_ids, non_null(list_of(:id))

      resolve &Level.Mutations.dismiss_mentions/2
    end

    @desc "Dismisses posts from the current user's inbox."
    field :dismiss_posts, type: :dismiss_posts_payload do
      arg :space_id, non_null(:id)
      arg :post_ids, non_null(list_of(:id))

      resolve &Level.Mutations.dismiss_posts/2
    end

    @desc "Marks posts as unread in a user's inbox."
    field :mark_as_unread, type: :mark_as_unread_payload do
      arg :space_id, non_null(:id)
      arg :post_ids, non_null(list_of(:id))

      resolve &Level.Mutations.mark_as_unread/2
    end

    @desc "Marks posts as read in a user's inbox."
    field :mark_as_read, type: :mark_as_unread_payload do
      arg :space_id, non_null(:id)
      arg :post_ids, non_null(list_of(:id))

      resolve &Level.Mutations.mark_as_read/2
    end

    @desc "Registers a push subscription."
    field :register_push_subscription, type: :register_push_subscription_payload do
      arg :data, non_null(:string)

      resolve &Level.Mutations.register_push_subscription/2
    end

    @desc "Marks the list of replies as viewed by the current user."
    field :record_reply_views, type: :record_reply_views_payload do
      arg :space_id, non_null(:id)
      arg :reply_ids, non_null(list_of(:id))

      resolve &Level.Mutations.record_reply_views/2
    end

    @desc "Marks a post as closed."
    field :close_post, :close_post_payload do
      arg :space_id, non_null(:id)
      arg :post_id, non_null(:id)

      resolve &Level.Mutations.close_post/2
    end

    @desc "Marks a post as open."
    field :reopen_post, :reopen_post_payload do
      arg :space_id, non_null(:id)
      arg :post_id, non_null(:id)

      resolve &Level.Mutations.reopen_post/2
    end
  end

  subscription do
    @desc "Triggered when a space-related event occurs."
    field :space_subscription, :space_subscription_payload do
      arg :space_id, non_null(:id)

      config fn %{space_id: space_id}, %{context: %{current_user: user}} ->
        case Spaces.get_space(user, space_id) do
          {:ok, _} ->
            {:ok, topic: space_id}

          err ->
            err
        end
      end
    end

    @desc "Triggered when a space user-related event occurs."
    field :space_user_subscription, :space_user_subscription_payload do
      arg :space_user_id, non_null(:id)

      config fn %{space_user_id: id}, %{context: %{current_user: user}} ->
        case Spaces.get_space_user(user, id) do
          {:ok, space_user} ->
            if space_user.user_id == user.id do
              {:ok, topic: id}
            else
              {:error, dgettext("errors", "Subscription not authorized")}
            end

          err ->
            err
        end
      end
    end

    @desc "Triggered when a group-related event occurs."
    field :group_subscription, :group_subscription_payload do
      arg :group_id, non_null(:id)

      config fn %{group_id: id}, %{context: %{current_user: user}} ->
        case Groups.get_group(user, id) do
          {:ok, group} ->
            {:ok, topic: group.id}

          err ->
            err
        end
      end
    end

    @desc "Triggered when a post-related event occurs."
    field :post_subscription, :post_subscription_payload do
      arg :post_id, non_null(:id)

      config fn %{post_id: id}, %{context: %{current_user: user}} ->
        case Posts.get_post(user, id) do
          {:ok, post} ->
            {:ok, topic: post.id}

          err ->
            err
        end
      end
    end
  end
end
