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
    make_request(state, payload, 0)
  end

  @impl true
  def handle_info({:retry_web_push, payload, attempts}, state) do
    make_request(state, payload, attempts)
  end

  defp make_request(state, payload, attempts) do
    payload
    |> adapter().make_request(state.subscription)
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
    {:stop, :normal, state}
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
    if attempts < max_attempts() - 1 do
      schedule_retry(payload, attempts + 1)
    end

    {:noreply, state}
  end

  defp schedule_retry(payload, attempts) do
    timeout = retry_timeout()
    message = {:retry_web_push, payload, attempts}

    if timeout > 0 do
      Process.send_after(self(), message, timeout)
    else
      send(self(), message)
    end
  end

  defp delete_subscription(digest) do
    digest
    |> by_digest()
    |> Repo.delete_all()
    |> handle_delete()
  end

  defp by_digest(digest) do
    from r in Schema, where: r.digest == ^digest
  end

  defp handle_delete(_), do: :ok

  # Internal

  defp adapter do
    Application.get_env(:level, Level.WebPush)[:adapter]
  end

  defp retry_timeout do
    Application.get_env(:level, Level.WebPush)[:retry_timeout]
  end

  defp max_attempts do
    Application.get_env(:level, Level.WebPush)[:max_attempts]
  end
end
