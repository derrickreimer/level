defmodule BridgeWeb.Schema.Types do
  @moduledoc """
  GraphQL type definitions.
  """

  use Absinthe.Schema.Notation
  alias BridgeWeb.Schema.Helpers

  import_types BridgeWeb.Schema.Enums
  import_types BridgeWeb.Schema.Scalars

  @desc "A `User` represents a person belonging to a specific `Team`."
  object :user do
    field :id, non_null(:id)
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
        batch({Helpers, :by_id, Bridge.Team}, user.team_id, fn batch_results ->
          {:ok, Map.get(batch_results, user.team_id)}
        end)
      end
    end
  end

  @desc "A `Team` is the main organizational unit for a Bridge account."
  object :team do
    field :id, non_null(:id)
    field :state, non_null(:team_state)
    field :name, non_null(:string)
    field :slug, non_null(:string)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :users, non_null(:user_connection) do
      arg :first, :integer
      arg :after, :cursor
      resolve &BridgeWeb.TeamResolver.users/3
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

  @desc "The response to inviting a user to a team."
  object :invite_user_payload do
    field :success, :boolean
    field :invitation, :invitation
    field :errors, list_of(:error)
  end

  @desc "A validation error."
  object :error do
    field :attribute, non_null(:string)
    field :message, non_null(:string)
  end

  object :page_info do
    field :start_cursor, :cursor
    field :end_cursor, :cursor
    field :has_next_page, non_null(:boolean)
    field :has_previous_page, non_null(:boolean)
  end

  object :user_edge do
    field :node, :user
    field :cursor, non_null(:cursor)
  end

  object :user_connection do
    field :edges, list_of(:user_edge)
    field :page_info, non_null(:page_info)
    field :total_count, non_null(:integer)
  end
end
