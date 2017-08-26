defmodule Bridge.Email do
  @moduledoc """
  Transactional emails sent by Bridge.
  """

  import Bamboo.Email
  use Bamboo.Phoenix, view: BridgeWeb.EmailView

  import BridgeWeb.UrlHelpers
  import BridgeWeb.Router.Helpers

  @doc """
  The email sent when a user invites another user to join a Bridge team.
  """
  def invitation_email(invitation) do
    team = invitation.team
    invitor = invitation.invitor
    invitation_url = build_url_with_subdomain(team.slug,
      invitation_path(BridgeWeb.Endpoint, :show, invitation))

    new_email()
    |> to(invitation.email)
    |> from({"Bridge", support_address()})
    |> subject("Your invitation to join the #{team.name} Bridge team")
    |> put_html_layout({BridgeWeb.LayoutView, "plain_text_email.html"})
    |> render("invitation_email.html", invitation: invitation,
                                       team: team,
                                       invitor: invitor,
                                       invitation_url: invitation_url)
  end

  def support_address do
    "support@#{Application.get_env(:bridge, :mailer_host)}"
  end
end
