defmodule BridgeWeb.DraftResolver do
  @moduledoc """
  GraphQL query resolution for drafts.
  """

  import BridgeWeb.ResolverHelpers
  import Bridge.Gettext
  alias Bridge.Threads

  def create(args, info) do
    user = info.context.current_user

    changeset =
      args
      |> Map.put(:user_id, user.id)
      |> Map.put(:team_id, user.team_id)
      |> Threads.create_draft_changeset()

    resp = case Threads.create_draft(changeset) do
      {:ok, draft} ->
        %{success: true, draft: draft, errors: []}

      {:error, changeset} ->
        %{success: false, draft: nil, errors: format_errors(changeset)}
    end

    {:ok, resp}
  end

  def update(args, info) do
    user = info.context.current_user

    resp =
      case Threads.get_draft_for_user(user, args.id) do
        nil ->
          errors = [%{attribute: "base", message: dgettext("errors", "Draft not found")}]
          %{success: false, draft: nil, errors: errors}

        draft ->
          case Threads.update_draft(draft, args) do
            {:ok, draft} ->
              %{success: true, draft: draft, errors: []}

            {:error, changeset} ->
              %{success: false, draft: draft, errors: format_errors(changeset)}
          end
      end

    {:ok, resp}
  end

  def destroy(%{id: id}, _info) do
    resp = case Threads.delete_draft(id) do
      {:ok, _} ->
        %{
          success: true,
          errors: []
        }
      {:error, message} ->
        %{
          success: false,
          errors: [%{attribute: "base", message: message}]
        }
    end

    {:ok, resp}
  end
end
