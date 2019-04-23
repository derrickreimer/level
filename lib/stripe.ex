defmodule Stripe do
  @moduledoc """
  A lightweight API wrapper for Stripe.
  """

  @doc """
  Builds a new client.
  """
  def client(api_key) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.stripe.com/v1"},
      {Tesla.Middleware.BasicAuth, [username: api_key, password: ""]},
      Tesla.Middleware.FormUrlencoded,
      Tesla.Middleware.DecodeJson
    ]

    Tesla.client(middleware)
  end

  @doc """
  Creates a customer record.
  """
  def create_customer(client, email) do
    Tesla.post(client, "/customers", %{"email" => email})
  end

  @doc """
  Subscribers a customer to a plan.
  """
  def create_subscription(client, customer_id, plan_id, quantity) do
    Tesla.post(client, "/subscriptions", %{
      "customer" => customer_id,
      "items[0][plan]" => plan_id,
      "items[0][quantity]" => quantity,
      "trial_from_plan" => true
    })
  end
end
