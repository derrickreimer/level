defmodule Bridge.Web.TeamResolver do
  def all(_args, _info) do
    {:ok, Bridge.Repo.all(Bridge.Team)}
  end
end
