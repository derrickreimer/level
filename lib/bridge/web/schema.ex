defmodule Bridge.Web.Schema do
  @moduledoc """
  GraphQL schema.
  """

  use Absinthe.Schema
  import_types Bridge.Web.Schema.Types

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

      resolve &Bridge.Web.InvitationResolver.create/2
    end
  end
end
