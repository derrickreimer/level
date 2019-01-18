defmodule Level.WebPush.Payload do
  @moduledoc """
  Represents a web push payload.
  """

  @enforce_keys [:body]
  defstruct body: "", tag: nil, require_interaction: false, click_url: nil

  @type t :: %__MODULE__{
          body: String.t(),
          tag: String.t() | nil,
          require_interaction: boolean(),
          click_url: String.t() | nil
        }

  @doc """
  Serializes a web push payload.
  """
  @spec serialize(t()) :: String.t() | no_return()
  def serialize(%__MODULE__{} = payload) do
    payload
    |> Map.from_struct()
    |> Poison.encode!()
  end
end
