defmodule Level.WebPush do
  @moduledoc """
  Functions for sending web push notifications.
  """

  import Ecto.Query

  alias Ecto.Changeset
  alias Level.WebPush.Payload
  alias Level.WebPush.Schema
  alias Level.WebPush.Subscription

  @doc """
  Registers a push subscription.
  """
  @spec subscribe(String.t(), String.t(), repo: Ecto.Repo.t()) ::
          {:ok, Subscription.t()} | {:error, :invalid_keys | :parse_error | :database_error}
  def subscribe(user_id, data, [repo: _] = opts) do
    case parse_subscription(data) do
      {:ok, subscription} ->
        subscription
        |> persist(user_id, data, opts)
        |> after_persist()

      err ->
        err
    end
  end

  defp persist(subscription, user_id, data, repo: repo) do
    result =
      %Schema{}
      |> Changeset.change(%{user_id: user_id, data: data})
      |> Changeset.change(%{digest: compute_digest(data)})
      |> repo.insert(on_conflict: :nothing)

    {result, subscription}
  end

  defp after_persist({{:ok, _}, subscription}) do
    {:ok, subscription}
  end

  defp after_persist({_, _}) do
    {:error, :database_error}
  end

  defp compute_digest(data) do
    :sha256
    |> :crypto.hash(data)
    |> Base.encode16()
  end

  @doc """
  Fetches all subscriptions for a list of user ids.
  """
  @spec get_subscriptions([String.t()], repo: Ecto.Repo.t()) :: %{
          optional(String.t()) => [Subscription.t()]
        }
  def get_subscriptions(user_ids, repo: repo) do
    user_ids
    |> build_query()
    |> repo.all()
    |> parse_records()
  end

  defp build_query(user_ids) do
    from r in Schema, where: r.user_id in ^user_ids
  end

  defp parse_records(records) do
    records
    |> Enum.map(fn %Schema{user_id: user_id, data: data} ->
      case parse_subscription(data) do
        {:ok, subscription} -> [user_id, subscription]
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.group_by(&List.first/1, &List.last/1)
  end

  @doc """
  Parses raw stringified JSON subscription data.
  """
  @spec parse_subscription(String.t()) ::
          {:ok, Subscription.t()}
          | {:error, :invalid_keys}
          | {:error, :parse_error}
  def parse_subscription(data) do
    Subscription.parse(data)
  end

  @doc """
  Sends a notification to a particular subscription.
  """
  @spec send_web_push(Payload.t(), Subscription.t()) ::
          {:ok, any()} | {:error, atom()} | no_return()
  def send_web_push(%Payload{} = payload, %Subscription{} = subscription) do
    payload
    |> Payload.serialize()
    |> adapter().send_web_push(subscription)
  end

  defp adapter do
    Application.get_env(:level, __MODULE__)[:adapter]
  end
end
