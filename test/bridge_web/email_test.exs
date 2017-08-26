defmodule BridgeWeb.EmailTest do
  use ExUnit.Case
  use Bamboo.Test

  describe "invitation_email/1" do
    setup do
      team = %Bridge.Teams.Team{name: "Acme", slug: "acme"}
      invitor = %Bridge.Teams.User{email: "derrick@acme.com"}

      invitation = %Bridge.Teams.Invitation{
        team: team,
        invitor: invitor,
        email: "bob@acme.com",
        token: "xxx"
      }

      email = BridgeWeb.Email.invitation_email(invitation)
      {:ok, %{email: email, invitation: invitation, team: team, invitor: invitor}}
    end

    test "sent to the invitee", %{email: email} do
      assert email.to == "bob@acme.com"
    end

    test "includes the team name and invitor", %{email: email} do
      assert email.html_body =~ "join the Acme team"
      assert email.html_body =~ "by derrick@acme.com"
      assert email.text_body =~ "join the Acme team"
      assert email.text_body =~ "by derrick@acme.com"
    end

    test "includes the invitation url", %{email: email} do
      assert email.html_body =~ "http://acme.bridge.test:4001/invitations/xxx"
      assert email.text_body =~ "http://acme.bridge.test:4001/invitations/xxx"
    end

    test "sends from support", %{email: email} do
      assert email.from == {"Bridge", "support@bridge.test"}
    end
  end
end
