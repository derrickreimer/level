defmodule LevelWeb.Schema.Types do
  @moduledoc """
  GraphQL type definitions.
  """

  use Absinthe.Schema.Notation
  alias LevelWeb.Schema.Helpers

  import_types LevelWeb.Schema.Enums
  import_types LevelWeb.Schema.Scalars
  import_types LevelWeb.Schema.InputObjects
  import_types LevelWeb.Schema.Connections
  import_types LevelWeb.Schema.Mutations

  @desc "A `User` represents a person belonging to a specific `Space`."
  object :user do
    field :id, non_null(:id)

    field :recipient_id, non_null(:id) do
      resolve fn user, _, _ ->
        {:ok, Level.Threads.get_recipient_id(user)}
      end
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

    field :space, non_null(:space) do
      resolve fn user, _, _ ->
        batch({Helpers, :by_id, Level.Spaces.Space}, user.space_id, fn batch_results ->
          {:ok, Map.get(batch_results, user.space_id)}
        end)
      end
    end

    field :drafts, non_null(:draft_connection) do
      arg :first, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :user_order
      resolve &LevelWeb.UserResolver.drafts/3
    end
  end

  @desc "A `Space` is the main organizational unit for a Level account."
  object :space do
    field :id, non_null(:id)
    field :state, non_null(:space_state)
    field :name, non_null(:string)
    field :slug, non_null(:string)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :users, non_null(:user_connection) do
      arg :first, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :user_order
      resolve &LevelWeb.SpaceResolver.users/3
    end
  end

  @desc "An `Invitation` is the means by which a new user joins an existing `Space`."
  object :invitation do
    field :id, non_null(:id)
    field :state, non_null(:invitation_state)
    field :invitor, non_null(:user)
    field :email, non_null(:string)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)
  end

  @desc "An `Draft` is an unsent thread that is still being composed."
  object :draft do
    field :id, non_null(:id)
    field :recipient_ids, list_of(:string)
    field :subject, non_null(:string)
    field :body, non_null(:string)
    field :is_truncated, non_null(:boolean)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :user, non_null(:user) do
      resolve fn draft, _, _ ->
        batch({Helpers, :by_id, Level.Spaces.User}, draft.user_id, fn batch_results ->
          {:ok, Map.get(batch_results, draft.user_id)}
        end)
      end
    end

    field :space, non_null(:space) do
      resolve fn draft, _, _ ->
        batch({Helpers, :by_id, Level.Spaces.Space}, draft.space_id, fn batch_results ->
          {:ok, Map.get(batch_results, draft.space_id)}
        end)
      end
    end
  end
end
