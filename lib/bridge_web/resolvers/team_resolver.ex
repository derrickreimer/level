defmodule BridgeWeb.TeamResolver do
  @moduledoc """
  GraphQL query resolution for teams.
  """

  def all(_args, _info) do
    {:ok, Bridge.Repo.all(Bridge.Team)}
  end
end
