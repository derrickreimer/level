defmodule Level.Billing do
  @moduledoc """
  The billing engine.
  """

  @adapter Application.get_env(:level, __MODULE__)[:adapter]

  def create_customer(email) do
    @adapter.create_customer(email)
  end

  def create_subscription(customer_id, plan_id, quantity) do
    @adapter.create_subscription(customer_id, plan_id, quantity)
  end
end
