defmodule LevelWeb.Absinthe do
  @moduledoc """
  A plug for establishing absinthe context.
  """

  alias Level.Groups
  alias Level.Repo

  @doc """
  Sets absinthe context on the given connection.
  """
  def put_absinthe_context(conn, _) do
    Absinthe.Plug.put_options(conn, context: build_context(conn))
  end

  defp build_context(%Plug.Conn{assigns: %{current_user: user}}) do
    %{current_user: user, loader: build_loader(user)}
  end

  defp build_context(_conn) do
    %{}
  end

  defp build_loader(user) do
    params = %{current_user: user}

    Dataloader.new()
    |> Dataloader.add_source(:db, Dataloader.Ecto.new(Repo))
    |> Dataloader.add_source(Groups, Groups.dataloader_data(params))
  end
end
