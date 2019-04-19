defmodule Level.Analytics.LiveAdapter do
  require Logger

  @behaviour Level.Analytics.Adapter
  @drip_config Application.get_env(:level, :drip)

  @impl Level.Analytics.Adapter
  def identify(email, properties) do
    params = Map.merge(properties, %{email: email})

    drip_client()
    |> Drip.create_or_update_subscriber(params)
    |> handle_identify(params)
  end

  defp handle_identify({:ok, %Tesla.Env{status: 200, body: body}}, _) do
    {:ok, body}
  end

  defp handle_identify(_, params) do
    Logger.error("identify call failed params=#{Jason.encode!(params)}")
    :error
  end

  @impl Level.Analytics.Adapter
  def track(email, action, properties) do
    params = %{
      email: email,
      action: action,
      properties: properties
    }

    drip_client()
    |> Drip.record_event(params)
    |> handle_track(params)
  end

  defp handle_track({:ok, %Tesla.Env{status: 204, body: body}}, _) do
    {:ok, body}
  end

  defp handle_track(_, params) do
    Logger.error("track call failed params=#{Jason.encode!(params)}")
    :error
  end

  defp drip_client do
    Drip.client(@drip_config[:account_id], @drip_config[:api_key])
  end
end
