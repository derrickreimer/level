defmodule BridgeWeb.InvitationResolver do
  @moduledoc """
  GraphQL query resolution for invitations.
  """

  import BridgeWeb.ResolverHelpers
  alias Bridge.Teams

  def create(args, info) do
    user = info.context.current_user

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
