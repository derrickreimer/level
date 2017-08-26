defmodule BridgeWeb.UserResolver do
  @moduledoc """
  GraphQL query resolution for users.
  """

  def drafts(user, args, _info) do
    Bridge.Connections.drafts(user, args, %{})
  end
end
