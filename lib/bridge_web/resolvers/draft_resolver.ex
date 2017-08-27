defmodule BridgeWeb.DraftResolver do
  @moduledoc """
  GraphQL query resolution for drafts.
  """

  import BridgeWeb.ResolverHelpers
  import Bridge.Gettext
  alias Bridge.Threads

  def create(args, %{context: %{current_user: user}}) do
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

  def update(args, %{context: %{current_user: user}}) do
    resp =
      case Threads.get_draft_for_user(user, args.id) do
        nil ->
          errors = [%{
            attribute: "base",
            message: dgettext("errors", "Draft not found")
          }]

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

  def destroy(%{id: id}, %{context: %{current_user: user}}) do
    resp =
      case Threads.get_draft_for_user(user, id) do
        nil ->
          errors = [%{attribute: "base", message: dgettext("errors", "Draft not found")}]
          %{success: false, errors: errors}

        draft ->
          case Threads.delete_draft(draft) do
            {:ok, _} ->
              %{success: true, errors: []}
            {:error, _} ->
              message = dgettext("errors", "An unexpected error occurred")
              errors = [%{attribute: "base", message: message}]
              %{success: false, errors: errors}
          end
      end

    {:ok, resp}
  end
end
