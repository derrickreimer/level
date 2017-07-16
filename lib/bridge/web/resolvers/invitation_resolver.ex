defmodule Bridge.Web.InvitationResolver do
  @moduledoc """
  GraphQL query resolution for invitations.
  """

  alias Bridge.Invitation
  alias Bridge.Repo

  def create(args, info) do
    args =
      args
      |> Map.put(:invitor_id, info.context.current_user.id)
      |> Map.put(:team_id, info.context.current_user.team_id)

    changeset = Invitation.changeset(%Invitation{}, args)

    resp = case Repo.insert(changeset) do
      {:ok, invitation} ->
        %{success: true, invitation: invitation, errors: []}
      {:error, _changeset} ->
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
