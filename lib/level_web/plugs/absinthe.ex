defmodule LevelWeb.Absinthe do
  @moduledoc """
  A plug for establishing absinthe context.
  """

  alias Level.Groups
  alias Level.Repo
  alias Level.Posts
  alias Level.Spaces
  alias Level.Users.User

  # Suppress dialyzer warnings about dataloader functions
  @dialyzer {:nowarn_function, build_loader: 1}

  @doc """
  Sets absinthe context on the given connection.
  """
  def put_absinthe_context(conn, _) do
    current_user = conn.assigns[:current_user]
    Absinthe.Plug.put_options(conn, context: build_context(current_user))
  end

  def build_context(%User{} = user) do
    %{current_user: user, loader: build_loader(%{current_user: user})}
  end

  def build_context(_) do
    %{}
  end

  defp build_loader(params) do
    Dataloader.new()
    |> Dataloader.add_source(:db, Dataloader.Ecto.new(Repo))
    |> Dataloader.add_source(Groups, Groups.dataloader_data(params))
    |> Dataloader.add_source(Spaces, Spaces.dataloader_data(params))
    |> Dataloader.add_source(Posts, Posts.dataloader_data(params))
  end
end
