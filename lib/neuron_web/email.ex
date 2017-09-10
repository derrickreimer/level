defmodule NeuronWeb.Email do
  @moduledoc """
  Transactional emails sent by Neuron.
  """

  import Bamboo.Email
  use Bamboo.Phoenix, view: NeuronWeb.EmailView

  import NeuronWeb.UrlHelpers
  import NeuronWeb.Router.Helpers

  @doc """
  The email sent when a user invites another user to join a Neuron team.
  """
  def invitation_email(invitation) do
    team = invitation.team
    invitor = invitation.invitor
    invitation_url = build_url_with_subdomain(team.slug,
      invitation_path(NeuronWeb.Endpoint, :show, invitation))

    new_email()
    |> to(invitation.email)
    |> from({"Neuron", support_address()})
    |> subject("Your invitation to join the #{team.name} Neuron team")
    |> put_html_layout({NeuronWeb.LayoutView, "plain_text_email.html"})
    |> render(:invitation_email, invitation: invitation,
                                 team: team,
                                 invitor: invitor,
                                 invitation_url: invitation_url)
  end

  def support_address do
    "support@#{Application.get_env(:neuron, :mailer_host)}"
  end
end
