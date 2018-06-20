defmodule LevelWeb.Schema do
  @moduledoc false

  use Absinthe.Schema
  import_types LevelWeb.Schema.Types

  alias Level.Spaces
  alias Level.Groups
  import Level.Gettext

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
    @desc "Create a space."
    field :create_space, type: :create_space_payload do
      arg :name, non_null(:string)
      arg :slug, non_null(:string)

      resolve &Level.Mutations.create_space/2
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
  end

  subscription do
    @desc "Triggered when a group is bookmarked."
    field :group_bookmarked, :group_bookmarked_payload do
      arg :space_user_id, non_null(:id)
      config &space_user_topic_config/2
    end

    @desc "Triggered when a group is unbookmarked."
    field :group_unbookmarked, :group_unbookmarked_payload do
      arg :space_user_id, non_null(:id)
      config &space_user_topic_config/2
    end

    @desc "Triggered when a post is created."
    field :post_created, :post_created_payload do
      arg :group_id, non_null(:id)
      config &group_topic_config/2
    end

    @desc "Triggered when group membership is updated."
    field :group_membership_updated, :group_membership_updated_payload do
      arg :group_id, non_null(:id)
      config &group_topic_config/2
    end

    @desc "Triggered when a group is updated."
    field :group_updated, :group_updated_payload do
      arg :group_id, non_null(:id)
      config &group_topic_config/2
    end
  end

  def space_user_topic_config(%{space_user_id: id}, %{context: %{current_user: user}}) do
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

  def group_topic_config(%{group_id: id}, %{context: %{current_user: user}}) do
    case Groups.get_group(user, id) do
      {:ok, group} ->
        {:ok, topic: group.id}

      err ->
        err
    end
  end
end
