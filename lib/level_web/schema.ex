defmodule LevelWeb.Schema do
  @moduledoc false

  use Absinthe.Schema
  import_types(LevelWeb.Schema.Types)

  alias Level.Spaces

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Spaces, Spaces.data())

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
  end

  mutation do
    @desc "Invite a person to a space via email."
    field :invite_user, type: :invite_user_payload do
      arg(:email, non_null(:string))

      resolve(&LevelWeb.InvitationResolver.create/2)
    end

    @desc "Revoke an invitation."
    field :revoke_invitation, type: :revoke_invitation_payload do
      arg(:id, non_null(:id))

      resolve(&LevelWeb.InvitationResolver.revoke/2)
    end
  end
end
