defmodule LevelWeb.Schema do
  @moduledoc false

  use Absinthe.Schema
  import_types(LevelWeb.Schema.Types)

  alias Level.Repo

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(:db, Dataloader.Ecto.new(Repo))

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  query do
    @desc "The currently authenticated user."
    field :viewer, :user do
      resolve(fn _, %{context: %{current_user: current_user}} ->
        {:ok, current_user}
      end)
    end

    @desc "Fetches a space by id."
    field :space, :space do
      arg :id, non_null(:id)
      resolve &Level.Connections.space/3
    end
  end

  mutation do
    @desc "Create a group."
    field :create_group, type: :create_group_payload do
      arg(:space_id, non_null(:id))
      arg(:name, non_null(:string))
      arg(:description, :string)
      arg(:is_private, :boolean)

      resolve(&Level.Mutations.create_group/2)
    end

    @desc "Update a group."
    field :update_group, type: :update_group_payload do
      arg(:space_id, non_null(:id))
      arg(:group_id, non_null(:id))
      arg(:name, :string)
      arg(:description, :string)
      arg(:is_private, :boolean)

      resolve(&Level.Mutations.update_group/2)
    end

    @desc "Create a post."
    field :create_post, type: :create_post_payload do
      arg(:space_id, non_null(:id))
      arg(:body, non_null(:string))

      resolve(&Level.Mutations.create_post/2)
    end
  end
end
