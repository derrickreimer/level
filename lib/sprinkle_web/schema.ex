defmodule SprinkleWeb.Schema do
  @moduledoc """
  GraphQL schema.
  """

  use Absinthe.Schema
  import_types SprinkleWeb.Schema.Types

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

      resolve &SprinkleWeb.InvitationResolver.create/2
    end

    @desc "Create a new draft."
    field :create_draft, type: :create_draft_payload do
      arg :recipient_ids, list_of(:string)
      arg :subject, non_null(:string)
      arg :body, non_null(:string)

      resolve &SprinkleWeb.DraftResolver.create/2
    end

    @desc "Update a draft."
    field :update_draft, type: :update_draft_payload do
      arg :id, :id
      arg :recipient_ids, list_of(:string)
      arg :subject, :string
      arg :body, :string

      resolve &SprinkleWeb.DraftResolver.update/2
    end

    @desc "Delete a draft."
    field :delete_draft, type: :delete_draft_payload do
      arg :id, :id

      resolve &SprinkleWeb.DraftResolver.destroy/2
    end
  end
end
