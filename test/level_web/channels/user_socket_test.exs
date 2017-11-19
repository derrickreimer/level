defmodule LevelWeb.UserSocketTest do
  use LevelWeb.ChannelCase

  describe "connect/2" do
    setup do
      absinthe_socket =
        "asdf" # A dummy value to demonstrate that it doesn't matter
        |> socket(absinthe: %{schema: Schema, opts: []})

      {:ok, %{absinthe_socket: absinthe_socket}}
    end

    test "returns socket with user set in context if token is valid",
      %{absinthe_socket: absinthe_socket} do
      {:ok, %{user: user}} = insert_signup()
      token = LevelWeb.Auth.generate_signed_jwt(user)
      params = %{"token" => token}

      {:ok, %Phoenix.Socket{assigns: %{
        absinthe: %{opts: [context: %{current_user: current_user}]}}
      }} = LevelWeb.UserSocket.connect(params, absinthe_socket)

      assert current_user.id == user.id
    end

    test "returns error if the token is invalid", %{absinthe_socket: absinthe_socket} do
      assert LevelWeb.UserSocket.connect(%{"token" => "foo"}, absinthe_socket) == :error
    end
  end
end
