defmodule BridgeWeb.Schema.Mutations do
  @moduledoc """
  GraphQL type definitions for mutations.
  """

  use Absinthe.Schema.Notation
  alias BridgeWeb.Schema.Helpers

  @desc "A validation error."
  object :error do
    @desc "The name of the invalid attribute."
    field :attribute, non_null(:string)

    @desc "A human-friendly error message."
    field :message, non_null(:string)
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
    The newly-created object. If the mutation was not successful,
    this field will be null.
    """
    field :invitation, :invitation
  end

  @desc "The response to creating a draft."
  object :create_draft_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, :boolean

    @desc "A list of validation errors."
    field :errors, list_of(:error)

    @desc """
    The newly-created object. If the mutation was not successful,
    this field will be null.
    """
    field :draft, :draft
  end

  @desc "The response to deleting a draft."
  object :delete_draft_payload do
    @desc """
    A boolean indicating if the mutation was successful. If true, the errors
    list will be empty. Otherwise, errors may contain objects describing why
    the mutation failed.
    """
    field :success, :boolean

    @desc "A list of validation errors."
    field :errors, list_of(:error)
  end
end
