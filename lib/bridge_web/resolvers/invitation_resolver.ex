defmodule BridgeWeb.InvitationResolver do
  @moduledoc """
  GraphQL query resolution for invitations.
  """

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

  def format_errors(%Ecto.Changeset{errors: errors}) do
    Enum.map(errors, fn({attr, {msg, props}}) ->
      message = Enum.reduce props, msg, fn {k, v}, acc ->
        String.replace(acc, "%{#{k}}", to_string(v))
      end

      %{attribute: attr, message: message}
    end)
  end
end
