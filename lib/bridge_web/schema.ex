defmodule BridgeWeb.Schema do
  @moduledoc """
  GraphQL schema.
  """

  use Absinthe.Schema
  import_types BridgeWeb.Schema.Types

  query do
    @desc "The currently authenticated user."
    field :viewer, :user do
      resolve fn _, %{context: %{current_user: current_user}} ->
        {:ok, current_user}
      end
    end
  end

  mutation do
    @desc "Invite a person to a team via email."
    field :invite_user, type: :invite_user_payload do
      arg :email, non_null(:string)

      resolve &BridgeWeb.InvitationResolver.create/2
    end

    @desc "Create a new thread draft."
    field :create_draft, type: :create_draft_payload do
      arg :recipients, list_of(:string)
      arg :subject, non_null(:string)
      arg :body, non_null(:string)

      resolve &BridgeWeb.DraftResolver.create/2
    end
  end
end
