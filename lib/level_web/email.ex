defmodule LevelWeb.Email do
  @moduledoc """
  Transactional emails sent by Level.
  """

  import Bamboo.Email
  use Bamboo.Phoenix, view: LevelWeb.EmailView

  import LevelWeb.UrlHelpers
  import LevelWeb.Router.Helpers

  @doc """
  The email sent when a user invites another user to join a Level team.
  """
  def invitation_email(invitation) do
    team = invitation.team
    invitor = invitation.invitor
    invitation_url = build_url_with_subdomain(team.slug,
      invitation_path(LevelWeb.Endpoint, :show, invitation))

    new_email()
    |> to(invitation.email)
    |> from({"Level", support_address()})
    |> subject("Your invitation to join the #{team.name} Level team")
    |> put_html_layout({LevelWeb.LayoutView, "plain_text_email.html"})
    |> render(:invitation_email, invitation: invitation,
                                 team: team,
                                 invitor: invitor,
                                 invitation_url: invitation_url)
  end

  def support_address do
    "support@#{Application.get_env(:level, :mailer_host)}"
  end
end
