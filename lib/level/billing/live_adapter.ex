defmodule Level.Billing.LiveAdapter do
  @moduledoc false

  require Logger

  @behaviour Level.Billing.Adapter
  @stripe_config Application.get_env(:level, :stripe)

  @impl Level.Billing.Adapter
  def create_customer(email) do
    params = %{"email" => email}

    stripe_client()
    |> Stripe.create_customer(params)
    |> after_create_customer(email)
  end

  defp after_create_customer({:ok, %Tesla.Env{status: 200, body: body}}, _email) do
    {:ok, body}
  end

  defp after_create_customer({:ok, %Tesla.Env{status: status, body: body}}, email) do
    message =
      "[stripe] create customer failed " <>
        "email=#{email} status=#{status} body=#{Jason.encode!(body)}"

    Logger.error(message)
    :error
  end

  defp after_create_customer(_, email) do
    Logger.error("[stripe] create customer failed email=#{email}")
    :error
  end

  @impl Level.Billing.Adapter
  def create_subscription(customer_id, plan_id, quantity) do
    params = %{
      "customer" => customer_id,
      "items[0][plan]" => plan_id,
      "items[0][quantity]" => quantity,
      "trial_from_plan" => true
    }

    stripe_client()
    |> Stripe.create_subscription(params)
    |> after_create_subscription(customer_id)
  end

  defp after_create_subscription({:ok, %Tesla.Env{status: 200, body: body}}, _customer_id) do
    {:ok, body}
  end

  defp after_create_subscription({:ok, %Tesla.Env{status: status, body: body}}, customer_id) do
    message =
      "[stripe] create subscription failed " <>
        "customer_id=#{customer_id} status=#{status} body=#{Jason.encode!(body)}"

    Logger.error(message)
    :error
  end

  defp after_create_subscription(_, customer_id) do
    Logger.error("[stripe] create subscription failed customer_id=#{customer_id}")
    :error
  end

  defp stripe_client do
    Stripe.client(@stripe_config[:private_key])
  end
end
