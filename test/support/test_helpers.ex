defmodule Bridge.TestHelpers do
  @moduledoc """
  Miscellaneous helper functions for tests.
  """

  alias Bridge.Repo
  alias Bridge.Threads

  def valid_signup_params do
    salt = random_string()

    %{
      slug: "team#{salt}",
      team_name: "Bridge, Inc.",
      username: "user#{salt}",
      email: "user#{salt}@bridge.chat",
      password: "$ecret$"
    }
  end

  def valid_user_params do
    salt = random_string()

    %{
      username: "user#{salt}",
      email: "user#{salt}@bridge.chat",
      password: "$ecret$"
    }
  end

  def valid_invitation_params(%{team: team, invitor: invitor}) do
    %{
      team_id: team.id,
      invitor_id: invitor.id,
      email: "user#{random_string()}@bridge.chat"
    }
  end

  def valid_draft_params(%{team: team, user: user}) do
    %{
      team_id: team.id,
      user_id: user.id,
      subject: "This is the subject",
      body: "I am the body",
      recipient_ids: []
    }
  end

  def insert_signup(params \\ %{}) do
    params =
      valid_signup_params()
      |> Map.merge(params)

    %{}
    |> Bridge.Teams.registration_changeset(params)
    |> Bridge.Teams.register()
  end

  def insert_member(team, params \\ %{}) do
    params =
      valid_user_params()
      |> Map.put(:team_id, team.id)
      |> Map.merge(params)

    %Bridge.Teams.User{}
    |> Bridge.Teams.User.signup_changeset(params)
    |> Repo.insert()
  end

  def insert_draft(team, user, params \\ %{}) do
    params =
      valid_draft_params(%{team: team, user: user})
      |> Map.merge(params)

    params
    |> Threads.create_draft_changeset()
    |> Threads.create_draft()
  end

  def put_launch_host(conn) do
    %{conn | host: "launch.bridge.test"}
  end

  def put_team_host(conn, team) do
    %{conn | host: "#{team.slug}.bridge.test"}
  end

  defp random_string do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode16()
    |> String.downcase
  end
end
