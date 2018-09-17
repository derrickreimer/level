defmodule Level.WebPush.SubscriptionSupervisor do
  @moduledoc """
  The supervisor for subscription processes.
  """

  use DynamicSupervisor

  alias Level.WebPush.SubscriptionWorker

  # Client

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def start_worker(id, subscription) do
    spec = {SubscriptionWorker, [id, subscription]}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  # Server

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
