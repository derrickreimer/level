defmodule Level.TestHelpers do
  @moduledoc """
  Miscellaneous helper functions for tests.
  """

  alias Level.Repo
  alias Level.Groups

  def valid_signup_params do
    salt = random_string()

    %{
      slug: "#{salt}",
      space_name: "Level, Inc.",
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
      email: "user#{salt}@level.live",
      password: "$ecret$"
    }
  end

  def valid_invitation_params do
    %{
      email: "user#{random_string()}@level.live"
    }
  end

  def valid_group_params do
    %{
      name: "Group#{random_string()}",
      description: "Some description",
      is_private: false
    }
  end

  def insert_signup(params \\ %{}) do
    params =
      valid_signup_params()
      |> Map.merge(params)

    %{}
    |> Level.Spaces.registration_changeset(params)
    |> Level.Spaces.register()
  end

  def insert_invitation(user, params \\ %{}) do
    params =
      valid_invitation_params()
      |> Map.merge(params)

    Level.Spaces.create_invitation(user, params)
  end

  def insert_member(space, params \\ %{}) do
    params =
      valid_user_params()
      |> Map.put(:space_id, space.id)
      |> Map.merge(params)

    %Level.Spaces.User{}
    |> Level.Spaces.User.signup_changeset(params)
    |> Repo.insert()
  end

  def insert_group(space, creator, params \\ %{}) do
    params =
      valid_group_params()
      |> Map.merge(params)

    Groups.create_group(space, creator, params)
  end

  def put_launch_host(conn) do
    %{conn | host: "launch.level.test"}
  end

  def put_space_host(conn, space) do
    %{conn | host: "#{space.slug}.level.test"}
  end

  defp random_string do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode16()
    |> String.downcase()
  end
end
