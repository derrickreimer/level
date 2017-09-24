defmodule LevelWeb.UserResolver do
  @moduledoc """
  GraphQL query resolution for users.
  """

  def drafts(user, args, _info) do
    Level.Connections.drafts(user, args, %{})
  end
end
