defmodule LevelWeb.InvitationResolver do
  @moduledoc """
  GraphQL query resolution for invitations.
  """

  import LevelWeb.ResolverHelpers
  import Level.Gettext
  alias Level.Spaces
  alias Level.Repo

  def create(args, %{context: %{current_user: user}}) do
    resp =
      case Spaces.create_invitation(user, args) do
        {:ok, invitation} ->
          %{success: true, invitation: invitation, errors: []}

        {:error, changeset} ->
          %{success: false, invitation: nil, errors: format_errors(changeset)}
      end

    {:ok, resp}
  end

  def revoke(args, %{context: %{current_user: user}}) do
    user = Repo.preload(user, :space)

    resp =
      case Spaces.get_pending_invitation(user.space, args.id) do
        nil ->
          %{
            success: false,
            invitation: nil,
            errors: [
              %{
                attribute: "base",
                message: dgettext("errors", "Invitation not found")
              }
            ]
          }

        invitation ->
          case Spaces.revoke_invitation(invitation) do
            {:ok, _} ->
              %{success: true, invitation: invitation, errors: []}

            {:error, _} ->
              %{success: false, invitation: invitation, errors: []}
          end
      end

    {:ok, resp}
  end
end
