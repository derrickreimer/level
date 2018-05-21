defmodule Level.TestHelpers do
  @moduledoc """
  Miscellaneous helper functions for tests.
  """

  alias Level.Groups
  alias Level.Posts
  alias Level.Spaces
  alias Level.Users

  def valid_user_params do
    salt = random_string()

    %{
      first_name: "Jane",
      last_name: "Doe",
      email: "user#{salt}@level.live",
      password: "$ecret$"
    }
  end

  def valid_space_params do
    salt = random_string()

    %{
      name: "Space#{salt}",
      slug: "space-#{salt}"
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

  def valid_post_params do
    %{
      body: "Hello world"
    }
  end

  def create_user_and_space(user_params \\ %{}, space_params \\ %{}) do
    user_params = valid_user_params() |> Map.merge(user_params)
    space_params = valid_space_params() |> Map.merge(space_params)

    {:ok, user} = Users.create_user(user_params)
    {:ok, space_and_space_user} = Spaces.create_space(user, space_params)
    {:ok, Map.put(space_and_space_user, :user, user)}
  end

  def create_user(params \\ %{}) do
    params =
      valid_user_params()
      |> Map.merge(params)

    Users.create_user(params)
  end

  def create_space(user, params \\ %{}) do
    params =
      valid_space_params()
      |> Map.merge(params)

    Spaces.create_space(user, params)
  end

  def create_space_member(space, user_params \\ %{}) do
    user_params =
      valid_user_params()
      |> Map.merge(user_params)

    {:ok, user} = Users.create_user(user_params)
    {:ok, space_user} = Spaces.create_member(user, space)
    {:ok, %{user: user, space_user: space_user}}
  end

  def create_group(member, params \\ %{}) do
    params =
      valid_group_params()
      |> Map.merge(params)

    Groups.create_group(member, params)
  end

  def post_to_group(space_user, group, params \\ %{}) do
    params =
      valid_post_params()
      |> Map.merge(params)

    Posts.post_to_group(space_user, group, params)
  end

  defp random_string do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode16()
    |> String.downcase()
  end
end
