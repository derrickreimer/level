defmodule Bridge.TestHelpers do
  alias Bridge.Repo

  def valid_signup_params do
    %{
      slug: "bridge",
      team_name: "Bridge, Inc.",
      username: "derrick",
      email: "derrick@bridge.chat",
      password: "$ecret$"
    }
  end

  def valid_invitation_params(%{team: team, invitor: invitor}) do
    %{
      team_id: team.id,
      invitor_id: invitor.id,
      email: "derrick@bridge.chat"
    }
  end

  def insert_signup(attrs \\ %{}) do
    random_string = Base.encode16(:crypto.strong_rand_bytes(8))
    username = "user#{random_string}"
    email = "#{username}@bridge.chat"
    slug = "team#{random_string}"

    changes = Map.merge(%{
      slug: slug,
      team_name: "Some team",
      username: username,
      email: email,
      password: "$ecret$",
      time_zone: "America/Chicago"
    }, attrs)

    %{}
    |> Bridge.Signup.form_changeset(changes)
    |> Bridge.Signup.transaction()
    |> Repo.transaction()
  end

  def put_launch_host(conn) do
    %{conn | host: "launch.bridge.test"}
  end

  def put_team_host(conn, team) do
    %{conn | host: "#{team.slug}.bridge.test"}
  end
end
