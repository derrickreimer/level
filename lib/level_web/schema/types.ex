defmodule LevelWeb.Schema.Types do
  @moduledoc false

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  alias Level.Groups
  alias Level.Spaces
  alias LevelWeb.Endpoint
  alias LevelWeb.Router.Helpers

  import_types LevelWeb.Schema.Enums
  import_types LevelWeb.Schema.Scalars
  import_types LevelWeb.Schema.InputObjects
  import_types LevelWeb.Schema.Connections
  import_types LevelWeb.Schema.Mutations
  import_types LevelWeb.Schema.Subscriptions

  @desc "A user represents a person belonging to a specific space."
  object :user do
    field :id, non_null(:id)
    field :state, non_null(:user_state)
    field :email, non_null(:string)
    field :first_name, :string
    field :last_name, :string
    field :time_zone, :string
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :space_users, non_null(:space_user_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :space_user_order
      resolve &Level.Connections.space_users/3
    end

    field :group_memberships, non_null(:group_membership_connection) do
      arg :space_id, non_null(:id)
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :group_order
      resolve &Level.Connections.group_memberships/3
    end
  end

  @desc "A space user defines a user's identity within a particular space."
  object :space_user do
    field :id, non_null(:id)
    field :state, non_null(:space_user_state)
    field :role, non_null(:space_user_role)
    field :space, non_null(:space), resolve: dataloader(Spaces)
    field :first_name, non_null(:string)
    field :last_name, non_null(:string)

    @desc "A list of groups the user has bookmarked."
    field :bookmarked_groups, list_of(:group) do
      resolve fn space_user, _args, %{context: %{current_user: user}} ->
        if space_user.user_id == user.id do
          {:ok, Groups.list_bookmarked_groups(space_user)}
        else
          {:ok, nil}
        end
      end
    end
  end

  @desc "A space represents a company or organization."
  object :space do
    field :id, non_null(:id)
    field :state, non_null(:space_state)
    field :name, non_null(:string)
    field :slug, non_null(:string)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :setup_state, non_null(:space_setup_state) do
      resolve fn space, _args, _context ->
        Spaces.get_setup_state(space)
      end
    end

    @desc "The currently active open invitation URL for the space."
    field :open_invitation_url, :string do
      resolve fn space, _args, _context ->
        case Spaces.get_open_invitation(space) do
          {:ok, invitation} ->
            {:ok, Helpers.open_invitation_url(Endpoint, :show, invitation.token)}

          :revoked ->
            {:ok, nil}
        end
      end
    end

    field :groups, non_null(:group_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :group_order
      arg :state, :group_state
      resolve &Level.Connections.groups/3
    end

    field :group, non_null(:group) do
      arg :id, non_null(:id)
      resolve &Level.Connections.group/3
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
    field :space, non_null(:space), resolve: dataloader(Spaces)
    field :creator, non_null(:user), resolve: dataloader(:db)
  end

  @desc "A group membership defines the relationship between a user and group."
  object :group_membership do
    field :group, non_null(:group), resolve: dataloader(Groups)
  end

  @desc "A post represents a conversation."
  object :post do
    field :id, non_null(:id)
    field :state, non_null(:post_state)
    field :body, non_null(:string)
    field :space, non_null(:space), resolve: dataloader(Spaces)
    field :author, non_null(:space_user), resolve: dataloader(Spaces)
    field :groups, list_of(:group), resolve: dataloader(Groups)
  end
end
