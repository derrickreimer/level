defmodule LevelWeb.Schema.Types do
  @moduledoc false

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers
  alias Level.Spaces

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

    field :space, non_null(:space), resolve: dataloader(Spaces)
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

    field :invitations, non_null(:invitation_connection) do
      arg(:first, :integer)
      arg(:last, :integer)
      arg(:before, :cursor)
      arg(:after, :cursor)
      arg(:order_by, :invitation_order)
      resolve(&Level.Connections.invitations/3)
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

  @desc "An invitation is the means by which a new user joins an existing space."
  object :invitation do
    field :id, non_null(:id)
    field :state, non_null(:invitation_state)
    field :invitor, non_null(:user), resolve: dataloader(Spaces)
    field :email, non_null(:string)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)
  end

  @desc "A group is consists of a collection of users within a space."
  object :group do
    field :id, non_null(:id)
    field :state, non_null(:group_state)
    field :name, non_null(:string)
    field :description, :string
    field :is_private, non_null(:boolean)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)
    field :space, non_null(:space), resolve: dataloader(Spaces)
    field :creator, non_null(:user), resolve: dataloader(Spaces)
  end
end
