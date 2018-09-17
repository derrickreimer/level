defmodule Level.WebPush.SubscriptionWorker do
  @moduledoc """
  A worker process for sending notifications to a subscription.
  """

  use GenServer
  require Logger
  import Ecto.Query

  alias Level.Repo
  alias Level.WebPush.Payload
  alias Level.WebPush.Schema
  alias Level.WebPush.Subscription

  defstruct [:digest, :subscription]

  @type t :: %__MODULE__{
          digest: String.t(),
          subscription: Subscription.t()
        }

  @retry_delay 1000
  @max_attempts 5

  # Client

  def start_link([digest, subscription]) do
    GenServer.start_link(__MODULE__, [digest, subscription], name: via_tuple(digest))
  end

  def registry_key(digest) do
    {:web_push_subscription, digest}
  end

  defp via_tuple(digest) do
    {:via, Registry, {Level.Registry, registry_key(digest)}}
  end

  def send_web_push(digest, %Payload{} = payload) do
    GenServer.cast(via_tuple(digest), {:send_web_push, payload})
  end

  # Server

  @impl true
  def init([digest, subscription]) do
    {:ok, %__MODULE__{digest: digest, subscription: subscription}}
  end

  @impl true
  def handle_cast({:send_web_push, payload}, state) do
    do_send_web_push(state, payload, 0)
  end

  @impl true
  def handle_info({:retry_web_push, payload, attempts}, state) do
    do_send_web_push(state, payload, attempts)
  end

  defp do_send_web_push(state, payload, attempts) do
    payload
    |> Payload.serialize()
    |> adapter().send_web_push(state.subscription)
    |> handle_push_response(state, payload, attempts)
  end

  defp handle_push_response({:ok, %_{status_code: 201}}, state, _, _) do
    {:noreply, state}
  end

  defp handle_push_response({:ok, %_{status_code: 404}}, state, _, _) do
    delete_subscription(state.digest)
    {:stop, :normal, state}
  end

  defp handle_push_response({:ok, %_{status_code: 410}}, state, _, _) do
    delete_subscription(state.digest)
    {:noreply, state}
  end

  defp handle_push_response({:ok, %_{status_code: 400} = resp}, state, _, _) do
    Logger.error("Push notification request was invalid: #{inspect(resp)}")
    {:noreply, state}
  end

  defp handle_push_response({:ok, %_{status_code: 429} = resp}, state, _, _) do
    Logger.error("Push notifications were rate limited: #{inspect(resp)}")
    {:noreply, state}
  end

  defp handle_push_response({:ok, %_{status_code: 413} = resp}, state, _, _) do
    Logger.error("Push notification was too large: #{inspect(resp)}")
    {:noreply, state}
  end

  defp handle_push_response(_, state, payload, attempts) do
    if attempts < @max_attempts do
      schedule_retry(state.digest, payload, attempts + 1)
    end

    {:noreply, state}
  end

  defp schedule_retry(digest, payload, attempts) do
    Process.send_after(via_tuple(digest), {:retry_web_push, payload, attempts}, @retry_delay)
  end

  defp delete_subscription(digest) do
    digest
    |> build_query()
    |> Repo.delete_all()
  end

  defp build_query(digest) do
    from r in Schema, where: r.digest == ^digest
  end

  # Internal

  defp adapter do
    Application.get_env(:level, Level.WebPush)[:adapter]
  end
end
