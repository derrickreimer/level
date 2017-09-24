defmodule Level.TestHelpers do
  @moduledoc """
  Miscellaneous helper functions for tests.
  """

  alias Level.Repo
  alias Level.Threads

  def valid_signup_params do
    salt = random_string()

    %{
      slug: "team#{salt}",
      team_name: "Level, Inc.",
      username: "user#{salt}",
      first_name: "Jane",
      last_name: "Doe",
      email: "user#{salt}@level.live",
      password: "$ecret$"
    }
  end

  def valid_user_params do
    salt = random_string()

    %{
      first_name: "Jane",
      last_name: "Doe",
      username: "user#{salt}",
      email: "user#{salt}@level.live",
      password: "$ecret$"
    }
  end

  def valid_invitation_params(%{team: team, invitor: invitor}) do
    %{
      team_id: team.id,
      invitor_id: invitor.id,
      email: "user#{random_string()}@level.live"
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
    |> Level.Teams.registration_changeset(params)
    |> Level.Teams.register()
  end

  def insert_member(team, params \\ %{}) do
    params =
      valid_user_params()
      |> Map.put(:team_id, team.id)
      |> Map.merge(params)

    %Level.Teams.User{}
    |> Level.Teams.User.signup_changeset(params)
    |> Repo.insert()
  end

  def insert_draft(team, user, params \\ %{}) do
    params =
      %{team: team, user: user}
      |> valid_draft_params()
      |> Map.merge(params)

    params
    |> Threads.create_draft_changeset()
    |> Threads.create_draft()
  end

  def put_launch_host(conn) do
    %{conn | host: "launch.level.test"}
  end

  def put_team_host(conn, team) do
    %{conn | host: "#{team.slug}.level.test"}
  end

  defp random_string do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode16()
    |> String.downcase
  end
end
