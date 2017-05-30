defmodule Bridge.TestHelpers do
  alias Bridge.Repo

  def valid_signup_params do
    %{
      slug: "bridge",
      pod_name: "Bridge, Inc.",
      username: "derrick",
      email: "derrick@bridge.chat",
      password: "$ecret$"
    }
  end

  def insert_signup(attrs \\ %{}) do
    random_string = Base.encode16(:crypto.strong_rand_bytes(8))
    username = "user#{random_string}"
    email = "#{username}@bridge.chat"
    slug = "pod#{random_string}"

    changes = Map.merge(%{
      slug: slug,
      pod_name: "Some pod",
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
end
