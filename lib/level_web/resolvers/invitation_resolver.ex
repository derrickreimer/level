defmodule LevelWeb.InvitationResolver do
  @moduledoc """
  GraphQL query resolution for invitations.
  """

  import LevelWeb.ResolverHelpers
  alias Level.Spaces

  def create(args, %{context: %{current_user: user}}) do
    resp = case Spaces.create_invitation(user, args) do
      {:ok, invitation} ->
        %{success: true, invitation: invitation, errors: []}

      {:error, changeset} ->
        %{success: false, invitation: nil, errors: format_errors(changeset)}
    end

    {:ok, resp}
  end
end
