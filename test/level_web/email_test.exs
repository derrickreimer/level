defmodule LevelWeb.EmailTest do
  use ExUnit.Case, async: true
  use Bamboo.Test

  describe "invitation_email/1" do
    setup do
      space = %Level.Spaces.Space{name: "Acme", slug: "acme"}
      invitor = %Level.Spaces.User{email: "derrick@acme.com"}

      invitation = %Level.Spaces.Invitation{
        space: space,
        invitor: invitor,
        email: "bob@acme.com",
        token: "xxx"
      }

      email = LevelWeb.Email.invitation_email(invitation)
      {:ok, %{email: email, invitation: invitation, space: space, invitor: invitor}}
    end

    test "sent to the invitee", %{email: email} do
      assert email.to == "bob@acme.com"
    end

    test "includes the space name and invitor", %{email: email} do
      assert email.html_body =~ "join the Acme space"
      assert email.html_body =~ "by derrick@acme.com"
      assert email.text_body =~ "join the Acme space"
      assert email.text_body =~ "by derrick@acme.com"
    end

    test "includes the invitation url", %{email: email} do
      assert email.html_body =~ "/invitations/xxx"
      assert email.text_body =~ "/invitations/xxx"
    end

    test "sends from support", %{email: email} do
      assert email.from == {"Level", "support@level.test"}
    end
  end
end
