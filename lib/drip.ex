defmodule Drip do
  @moduledoc """
  A lightweight API wrapper for Drip.
  """

  @doc """
  Builds a new client.
  """
  def client(account_id, token) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.getdrip.com/v2/" <> account_id},
      {Tesla.Middleware.BasicAuth, [username: token, password: ""]},
      {Tesla.Middleware.JSON, [decode_content_types: ["application/vnd.api+json"]]},
      {Tesla.Middleware.Headers, [{"user-agent", "Level (level.app)"}]}
    ]

    Tesla.client(middleware)
  end

  @doc """
  Fetches a subscriber by ID or email.

  See https://developer.drip.com/#fetch-a-subscriber
  """
  def get_subscriber(client, id_or_email) do
    Tesla.get(client, "/subscribers/" <> id_or_email)
  end

  @doc """
  Creates or updates a subscriber.

  See https://developer.drip.com/#create-or-update-a-subscriber
  """
  def create_or_update_subscriber(client, params) do
    Tesla.post(client, "/subscribers", %{subscribers: [params]})
  end

  @doc """
  Records an event.

  See https://developer.drip.com/#record-an-event
  """
  def record_event(client, params) do
    Tesla.post(client, "/events", %{events: [params]})
  end
end
