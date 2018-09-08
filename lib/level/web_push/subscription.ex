defmodule Level.WebPush.Subscription do
  @enforce_keys [:endpoint, :auth, :p256dh]
  defstruct [:endpoint, :auth, :p256dh]

  @type t :: %__MODULE__{
          endpoint: String.t(),
          auth: String.t(),
          p256dh: String.t()
        }

  def parse(data) do
    data
    |> Poison.decode()
    |> after_decode()
  end

  defp after_decode(
         {:ok, %{"endpoint" => endpoint, "keys" => %{"auth" => auth, "p256dh" => p256dh}}}
       ) do
    {:ok, %__MODULE__{endpoint: endpoint, auth: auth, p256dh: p256dh}}
  end

  defp after_decode({:ok, _}) do
    {:error, :invalid_keys}
  end

  defp after_decode({:error, _}) do
    {:error, :parse_error}
  end

  defp after_decode({:error, _, _}) do
    {:error, :parse_error}
  end
end
