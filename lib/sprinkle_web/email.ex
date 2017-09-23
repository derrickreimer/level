defmodule SprinkleWeb.Email do
  @moduledoc """
  Transactional emails sent by Sprinkle.
  """

  import Bamboo.Email
  use Bamboo.Phoenix, view: SprinkleWeb.EmailView

  import SprinkleWeb.UrlHelpers
  import SprinkleWeb.Router.Helpers

  @doc """
  The email sent when a user invites another user to join a Sprinkle team.
  """
  def invitation_email(invitation) do
    team = invitation.team
    invitor = invitation.invitor
    invitation_url = build_url_with_subdomain(team.slug,
      invitation_path(SprinkleWeb.Endpoint, :show, invitation))

    new_email()
    |> to(invitation.email)
    |> from({"Sprinkle", support_address()})
    |> subject("Your invitation to join the #{team.name} Sprinkle team")
    |> put_html_layout({SprinkleWeb.LayoutView, "plain_text_email.html"})
    |> render(:invitation_email, invitation: invitation,
                                 team: team,
                                 invitor: invitor,
                                 invitation_url: invitation_url)
  end

  def support_address do
    "support@#{Application.get_env(:sprinkle, :mailer_host)}"
  end
end
