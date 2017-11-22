defmodule LevelWeb.UserSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Socket,
    schema: LevelWeb.Schema

  alias LevelWeb.Auth

  ## Channels
  # channel "room:*", Level.RoomChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket,
    timeout: 45_000

  # transport :longpoll, Phoenix.Transports.LongPoll

  def connect(%{"Authorization" => auth}, socket) do
    with "Bearer " <> token <- auth,
         {:ok, %{user: user}} <- Auth.get_user_by_token(token)
    do
      socket = Absinthe.Phoenix.Socket.put_opts(socket, context: %{
        current_user: user
      })

      {:ok, socket}
    else
      _ -> :error
    end
  end

  def connect(_params, _socket) do
    :error
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
  def id(_socket), do: nil
end
