defmodule LevelWeb.UserSocket do
  @moduledoc false

  use Phoenix.Socket
  use Absinthe.Phoenix.Socket, schema: LevelWeb.Schema

  alias LevelWeb.Auth

  ## Channels
  channel "posts:*", LevelWeb.PostChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket,
    timeout: 45_000,
    check_origin: false

  # transport :longpoll, Phoenix.Transports.LongPoll

  def connect(%{"Authorization" => auth}, socket) do
    with "Bearer " <> token <- auth,
         {:ok, %{user: user}} <- Auth.get_user_by_token(token) do
      socket_with_opts =
        socket
        |> put_absinthe_options(user)
        |> assign(:current_user, user)

      {:ok, socket_with_opts}
    else
      _ -> :error
    end
  end

  def connect(_params, _socket) do
    :error
  end

  defp put_absinthe_options(socket, user) do
    Absinthe.Phoenix.Socket.put_options(socket,
      context: LevelWeb.Absinthe.build_context(user)
    )
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Level.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(socket), do: "user_socket:#{socket.assigns.current_user.id}"
end
