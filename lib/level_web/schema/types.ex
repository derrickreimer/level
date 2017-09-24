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

  @desc "A `User` represents a person belonging to a specific `Team`."
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

    field :team, non_null(:team) do
      resolve fn user, _, _ ->
        batch({Helpers, :by_id, Level.Teams.Team}, user.team_id, fn batch_results ->
          {:ok, Map.get(batch_results, user.team_id)}
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

  @desc "A `Team` is the main organizational unit for a Level account."
  object :team do
    field :id, non_null(:id)
    field :state, non_null(:team_state)
    field :name, non_null(:string)
    field :slug, non_null(:string)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :users, non_null(:user_connection) do
      arg :first, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :user_order
      resolve &LevelWeb.TeamResolver.users/3
    end
  end

  @desc "An `Invitation` is the means by which a new user joins an existing `Team`."
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
        batch({Helpers, :by_id, Level.Teams.User}, draft.user_id, fn batch_results ->
          {:ok, Map.get(batch_results, draft.user_id)}
        end)
      end
    end

    field :team, non_null(:team) do
      resolve fn draft, _, _ ->
        batch({Helpers, :by_id, Level.Teams.Team}, draft.team_id, fn batch_results ->
          {:ok, Map.get(batch_results, draft.team_id)}
        end)
      end
    end
  end
end
