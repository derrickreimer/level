defmodule Bridge.Email do
  @moduledoc """
  Transactional emails sent by Bridge.
  """

  import Bamboo.Email
  use Bamboo.Phoenix, view: Bridge.Web.EmailView
  alias Bridge.Web.UrlHelpers

  @doc """
  The email sent when a user invites another user to join a Bridge team.
  """
  def invitation_email(invitation) do
    team = invitation.team
    invitor = invitation.invitor

    new_email()
    |> to(invitation.email)
    |> from({"Bridge", "invitations@#{UrlHelpers.root_domain()}"})
    |> subject("Your invitation to join the #{team.name} Bridge team")
    |> render("invitation_email.text", invitation: invitation,
                                       team: team,
                                       invitor: invitor)
  end
end
