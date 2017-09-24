defmodule LevelWeb.InvitationResolver do
  @moduledoc """
  GraphQL query resolution for invitations.
  """

  import LevelWeb.ResolverHelpers
  alias Level.Teams

  def create(args, %{context: %{current_user: user}}) do
    changeset =
      args
      |> Map.put(:invitor_id, user.id)
      |> Map.put(:team_id, user.team_id)
      |> Teams.create_invitation_changeset()

    resp = case Teams.create_invitation(changeset) do
      {:ok, invitation} ->
        %{success: true, invitation: invitation, errors: []}

      {:error, changeset} ->
        %{success: false, invitation: nil, errors: format_errors(changeset)}
    end

    {:ok, resp}
  end
end
