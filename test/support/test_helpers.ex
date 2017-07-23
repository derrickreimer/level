defmodule Bridge.TestHelpers do
  alias Bridge.Repo

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

  def insert_signup(attrs \\ %{}) do
    salt = random_string()

    username = "user#{salt}"
    email = "#{username}@bridge.chat"
    slug = "team#{salt}"

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

  defp random_string do
    Base.encode16(:crypto.strong_rand_bytes(8))
    |> String.downcase
  end
end
