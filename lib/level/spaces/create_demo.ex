defmodule Level.Spaces.CreateDemo do
  @moduledoc false

  alias Level.Repo
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.User
  alias Level.Spaces

  @spec perform(User.t()) :: {:ok, %{space: Space.t(), space_user: SpaceUser.t()}} | no_return()
  def perform(%User{} = user) do
    {:ok, %{space: space, space_user: space_user}} = create_space(user)

    # Do all the scaffolding...

    {:ok, %{space: space, space_user: space_user}}
  end

  defp create_space(user) do
    params = %{
      name: "CoffeeKit",
      slug: "coffeekit-#{generate_salt()}",
      is_demo: true,
      avatar: "https://s3.amazonaws.com/level-assets-prod/demo/team-avatar.png"
    }

    Spaces.create_space(user, params)
  end

  defp generate_salt do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode16()
    |> String.downcase()
  end
end
