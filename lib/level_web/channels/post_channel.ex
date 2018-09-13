defmodule LevelWeb.PostChannel do
  @moduledoc """
  Represents the post channel.
  """

  use LevelWeb, :channel

  alias Level.Posts
  alias LevelWeb.Presence

  @dialyzer [
    {:nowarn_function, handle_info: 2}
  ]

  def join("posts:" <> post_id, _payload, socket) do
    if authorized?(socket, post_id) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))

    {:ok, _} =
      Presence.track(socket, socket.assigns.current_user.id, %{
        online_at: inspect(System.system_time(:seconds))
      })

    {:noreply, socket}
  end

  defp authorized?(%{assigns: %{current_user: user}}, post_id) do
    case Posts.get_post(user, post_id) do
      {:ok, _post} ->
        true

      _ ->
        false
    end
  end
end
