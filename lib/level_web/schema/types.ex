defmodule LevelWeb.Schema.Types do
  @moduledoc false

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers
  alias Level.Spaces
  alias Level.Rooms

  import_types(LevelWeb.Schema.Enums)
  import_types(LevelWeb.Schema.Scalars)
  import_types(LevelWeb.Schema.InputObjects)
  import_types(LevelWeb.Schema.Connections)
  import_types(LevelWeb.Schema.Mutations)

  @desc "A user represents a person belonging to a specific space."
  object :user do
    field :id, non_null(:id)

    field :recipient_id, non_null(:id) do
      resolve(fn user, _, _ ->
        {:ok, Level.Threads.get_recipient_id(user)}
      end)
    end

    field :state, non_null(:user_state)
    field :role, non_null(:user_role)
    field :email, non_null(:string)
    field :username, non_null(:string)
    field :first_name, :string
    field :last_name, :string
    field :time_zone, :string
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :space, non_null(:space), resolve: dataloader(Spaces)

    field :drafts, non_null(:draft_connection) do
      arg(:first, :integer)
      arg(:last, :integer)
      arg(:before, :cursor)
      arg(:after, :cursor)
      arg(:order_by, :user_order)
      resolve(&LevelWeb.UserResolver.drafts/3)
    end

    field :room_subscriptions, non_null(:room_subscription_connection) do
      arg(:first, :integer)
      arg(:last, :integer)
      arg(:before, :cursor)
      arg(:after, :cursor)
      arg(:order_by, :room_subscription_order)
      resolve(&LevelWeb.UserResolver.room_subscriptions/3)
    end

    @desc "Fetch a room by id"
    field :room, :room do
      arg(:id, non_null(:id))
      resolve(&LevelWeb.UserResolver.room/3)
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
      resolve(&LevelWeb.SpaceResolver.users/3)
    end

    field :invitations, non_null(:invitation_connection) do
      arg(:first, :integer)
      arg(:last, :integer)
      arg(:before, :cursor)
      arg(:after, :cursor)
      arg(:order_by, :invitation_order)
      resolve(&LevelWeb.SpaceResolver.invitations/3)
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

  @desc "An draft is an unsent thread that is still being composed."
  object :draft do
    field :id, non_null(:id)
    field :recipient_ids, list_of(:string)
    field :subject, non_null(:string)
    field :body, non_null(:string)
    field :is_truncated, non_null(:boolean)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :user, non_null(:user), resolve: dataloader(Spaces)
    field :space, non_null(:space), resolve: dataloader(Spaces)
  end

  @desc "A room is a long-running thread for a particular team or group of users."
  object :room do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :description, non_null(:string)
    field :subscriber_policy, non_null(:room_subscriber_policy)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :messages, non_null(:room_message_connection) do
      arg(:first, :integer)
      arg(:last, :integer)
      arg(:before, :cursor)
      arg(:after, :cursor)
      arg(:order_by, :room_message_order)
      resolve(&LevelWeb.RoomResolver.messages/3)
    end

    field :users, non_null(:room_user_connection) do
      arg(:first, :integer)
      arg(:last, :integer)
      arg(:before, :cursor)
      arg(:after, :cursor)
      arg(:order_by, :user_order)
      resolve(&LevelWeb.RoomResolver.users/3)
    end

    field :creator, non_null(:user), resolve: dataloader(Spaces)
    field :space, non_null(:space), resolve: dataloader(Spaces)

    # TODO: This presents an N+1 query. Investigate using dataloader instead.
    field :last_message, :room_message do
      resolve(&LevelWeb.RoomResolver.last_message/3)
    end
  end

  @desc "A room subscription represents a user's membership in a room."
  object :room_subscription do
    field :id, non_null(:id)
    field :user, non_null(:user), resolve: dataloader(Spaces)
    field :space, non_null(:space), resolve: dataloader(Spaces)
    field :room, non_null(:room), resolve: dataloader(Spaces)
    field :last_read_message, :room_message, resolve: dataloader(Rooms)
    field :last_read_message_at, :time
  end

  @desc "A room message is message posted to a room."
  object :room_message do
    field :id, non_null(:id)
    field :body, non_null(:string)
    field :inserted_at, non_null(:time)

    field :inserted_at_ts, non_null(:timestamp) do
      resolve(fn room_message, _, _ ->
        {:ok, room_message.inserted_at}
      end)
    end

    field :space, non_null(:space), resolve: dataloader(Spaces)
    field :user, non_null(:user), resolve: dataloader(Spaces)
    field :room, non_null(:room), resolve: dataloader(Rooms)
    field :last_read_message, :room_message, resolve: dataloader(Rooms)
  end
end
