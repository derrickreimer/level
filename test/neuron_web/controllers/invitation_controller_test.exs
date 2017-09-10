defmodule NeuronWeb.InvitationControllerTest do
  use NeuronWeb.ConnCase

  # alias Neuron.Teams.Invitation
  alias Neuron.Teams

  setup %{conn: conn} do
    {:ok, %{team: team, user: owner}} = insert_signup()

    conn =
      conn
      |> put_team_host(team)

    {:ok, %{conn: conn, team: team, owner: owner}}
  end

  describe "GET /invitations/:id" do
    setup %{conn: conn, team: team, owner: owner} do
      changeset =
        %{team: team, invitor: owner}
        |> valid_invitation_params()
        |> Teams.create_invitation_changeset()
      
      {:ok, invitation} = Teams.create_invitation(changeset)
      {:ok, %{conn: conn, team: team, invitor: owner, invitation: invitation}}
    end

    test "displays the correct copy",
      %{conn: conn, team: team, invitor: invitor, invitation: invitation} do

      conn =
        conn
        |> get("/invitations/#{invitation.token}")

      response = html_response(conn, 200)
      assert response =~ "Join the #{team.name} team"
      assert response =~ "You were invited by #{invitor.email}"
    end

    test "returns a 404 if invitation does not exist", %{conn: conn} do
      assert_raise(Ecto.NoResultsError, fn ->
        conn
        |> get("/invitations/#{Ecto.UUID.generate()}")
      end)
    end
  end
end
