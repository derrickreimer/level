defmodule LevelWeb.Schema do
  @moduledoc false

  use Absinthe.Schema

  alias Level.Spaces
  alias Level.Groups

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
      arg :space_id, non_null(:id)
      resolve &Level.Connections.space_user/3
    end

    @desc "Fetches a space."
    field :space, :space do
      arg :id, non_null(:id)
      resolve &Level.Connections.space/3
    end
  end

  mutation do
    @desc "Update user settings."
    field :update_user, type: :update_user_payload do
      arg :first_name, :string
      arg :last_name, :string
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
      arg :is_private, :boolean

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

      resolve &Level.Mutations.update_group/2
    end

    @desc "Update a group membership."
    field :update_group_membership, type: :update_group_membership_payload do
      arg :space_id, non_null(:id)
      arg :group_id, non_null(:id)
      arg :state, non_null(:group_membership_state)

      resolve &Level.Mutations.update_group_membership/2
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
    field :post_to_group, type: :post_to_group_payload do
      arg :space_id, non_null(:id)
      arg :group_id, non_null(:id)
      arg :body, non_null(:string)

      resolve &Level.Mutations.post_to_group/2
    end

    @desc "Replies to a post."
    field :reply_to_post, type: :reply_to_post_payload do
      arg :space_id, non_null(:id)
      arg :post_id, non_null(:id)
      arg :body, non_null(:string)

      resolve &Level.Mutations.reply_to_post/2
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

      config fn %{post_id: id}, %{context: %{current_user: _user}} ->
        # TODO: add authorization
        {:ok, topic: id}
      end
    end
  end
end
