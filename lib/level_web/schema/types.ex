defmodule LevelWeb.Schema.Types do
  @moduledoc false

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  import_types(LevelWeb.Schema.Enums)
  import_types(LevelWeb.Schema.Scalars)
  import_types(LevelWeb.Schema.InputObjects)
  import_types(LevelWeb.Schema.Connections)
  import_types(LevelWeb.Schema.Mutations)

  @desc "A user represents a person belonging to a specific space."
  object :user do
    field :id, non_null(:id)
    field :state, non_null(:user_state)
    field :role, non_null(:user_role)
    field :email, non_null(:string)
    field :first_name, :string
    field :last_name, :string
    field :time_zone, :string
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :space, non_null(:space), resolve: dataloader(:db)

    field :group_memberships, non_null(:group_membership_connection) do
      arg(:first, :integer)
      arg(:last, :integer)
      arg(:before, :cursor)
      arg(:after, :cursor)
      arg(:order_by, :group_order)
      resolve(&Level.Connections.group_memberships/3)
    end
  end

  @desc "A space is the main organizational unit, typically representing a company or organization."
  object :space do
    field :id, non_null(:id)
    field :state, non_null(:space_state)
    field :name, non_null(:string)
    field :slug, non_null(:string)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :users, non_null(:user_connection) do
      arg(:first, :integer)
      arg(:last, :integer)
      arg(:before, :cursor)
      arg(:after, :cursor)
      arg(:order_by, :user_order)
      resolve(&Level.Connections.users/3)
    end

    field :groups, non_null(:group_connection) do
      arg(:first, :integer)
      arg(:last, :integer)
      arg(:before, :cursor)
      arg(:after, :cursor)
      arg(:order_by, :group_order)
      arg(:state, :group_state)
      resolve(&Level.Connections.groups/3)
    end
  end

  @desc "A group is a collection of users within a space."
  object :group do
    field :id, non_null(:id)
    field :state, non_null(:group_state)
    field :name, non_null(:string)
    field :description, :string
    field :is_private, non_null(:boolean)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)
    field :space, non_null(:space), resolve: dataloader(:db)
    field :creator, non_null(:user), resolve: dataloader(:db)
  end

  @desc "A group membership defines the relationship between a user and group."
  object :group_membership do
    field :group, non_null(:group), resolve: dataloader(:db)
  end

  @desc "A post represents a conversation."
  object :post do
    field :id, non_null(:id)
    field :state, non_null(:post_state)
    field :body, non_null(:string)
    field :space, non_null(:space), resolve: dataloader(:db)
    field :user, non_null(:user), resolve: dataloader(:db)
  end
end
