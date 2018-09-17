defmodule Level.WebPush.User do
  @moduledoc """
  A server process representing a user.
  """

  use GenServer

  import Ecto.Query

  alias Level.Repo
  alias Level.WebPush.Payload
  alias Level.WebPush.Schema
  alias Level.WebPush.Subscription

  defstruct [:user_id]

  # Client

  def start_link(user_id) do
    GenServer.start_link(__MODULE__, user_id, name: via_tuple(user_id))
  end

  def registry_key(user_id) do
    {:web_push_user, user_id}
  end

  defp via_tuple(user_id) do
    {:via, Registry, {Level.Registry, registry_key(user_id)}}
  end

  def send_web_push(user_id, %Payload{} = payload) do
    GenServer.cast(via_tuple(user_id), {:send_web_push, payload})
  end

  # Server

  @impl true
  def init(user_id) do
    {:ok, %__MODULE__{user_id: user_id}}
  end

  @impl true
  def handle_cast({:send_web_push, payload}, state) do
    state.user_id
    |> fetch_subscriptions()
    |> Enum.each(fn subscription ->
      send_to_subscription(payload, subscription)
    end)

    {:noreply, state}
  end

  # Internal

  defp fetch_subscriptions(user_id) do
    user_id
    |> build_query()
    |> Repo.all()
    |> parse_records()
  end

  defp build_query(user_id) do
    from r in Schema, where: r.user_id == ^user_id
  end

  defp parse_records(records) do
    records
    |> Enum.map(fn %Schema{data: data} ->
      case Subscription.parse(data) do
        {:ok, subscription} -> subscription
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp send_to_subscription(payload, subscription) do
    payload
    |> Payload.serialize()
    |> adapter().send_web_push(subscription)
  end

  defp adapter do
    Application.get_env(:level, Level.WebPush)[:adapter]
  end
end
