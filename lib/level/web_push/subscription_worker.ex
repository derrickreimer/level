defmodule Level.WebPush.SubscriptionWorker do
  @moduledoc """
  A worker process for sending notifications to a subscription.
  """

  use GenServer

  alias Level.WebPush.Payload
  alias Level.WebPush.Subscription

  defstruct [:subscription]

  @type t :: %__MODULE__{
          subscription: Subscription.t()
        }

  # Client

  def start_link([id, subscription]) do
    GenServer.start_link(__MODULE__, subscription, name: via_tuple(id))
  end

  def registry_key(id) do
    {:web_push_subscription, id}
  end

  defp via_tuple(id) do
    {:via, Registry, {Level.Registry, registry_key(id)}}
  end

  def send_web_push(id, %Payload{} = payload) do
    GenServer.cast(via_tuple(id), {:send_web_push, payload})
  end

  # Server

  @impl true
  def init(subscription) do
    {:ok, %__MODULE__{subscription: subscription}}
  end

  @impl true
  def handle_cast({:send_web_push, payload}, state) do
    payload
    |> Payload.serialize()
    |> adapter().send_web_push(state.subscription)

    {:noreply, state}
  end

  # Internal

  defp adapter do
    Application.get_env(:level, Level.WebPush)[:adapter]
  end
end
