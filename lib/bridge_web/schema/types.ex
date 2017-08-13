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
        batch({Helpers, :by_id, Bridge.Teams.Team}, user.team_id, fn batch_results ->
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
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :user_order
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
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, :boolean

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The newly-created invitation object. If the mutation was not successful,
    this field will be null.
    """
    field :invitation, :invitation
  end

  @desc "A validation error."
  object :error do
    @desc "The name of the invalid attribute."
    field :attribute, non_null(:string)

    @desc "A human-friendly error message."
    field :message, non_null(:string)
  end

  @desc "Data for pagination in a connection."
  object :page_info do
    @desc "The cursor correspodning to the first node."
    field :start_cursor, :cursor

    @desc "The cursor corresponding to the last node."
    field :end_cursor, :cursor

    @desc "A boolean indicating whether there are more items going forward."
    field :has_next_page, non_null(:boolean)

    @desc "A boolean indicating whether there are more items going backward."
    field :has_previous_page, non_null(:boolean)
  end

  @desc "An edge in the user connection."
  object :user_edge do
    @desc "The item at the edge of the node."
    field :node, :user

    @desc "A cursor for use in pagination."
    field :cursor, non_null(:cursor)
  end

  @desc "A list of users belonging to a team."
  object :user_connection do
    @desc "A list of edges."
    field :edges, list_of(:user_edge)

    @desc "Pagination data for the connection."
    field :page_info, non_null(:page_info)

    @desc "The total count of items in the connection."
    field :total_count, non_null(:integer)
  end

  @desc "The field and direction to sort users."
  input_object :user_order do
    @desc "The field by which to sort users."
    field :field, non_null(:user_order_field)

    @desc "The sort direction."
    field :direction, non_null(:order_direction)
  end
end
