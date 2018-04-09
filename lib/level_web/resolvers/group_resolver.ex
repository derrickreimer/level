defmodule LevelWeb.GroupResolver do
  @moduledoc """
  GraphQL query resolution for groups.
  """

  import LevelWeb.ResolverHelpers

  alias Level.Groups

  def create(args, %{context: %{current_user: user}}) do
    resp =
      case Groups.create_group(user, args) do
        {:ok, %{group: group}} ->
          %{success: true, group: group, errors: []}

        {:error, :group, changeset, _} ->
          %{success: false, group: nil, errors: format_errors(changeset)}

        _ ->
          %{success: false, group: nil, errors: []}
      end

    {:ok, resp}
  end

  def update(%{id: id} = args, _) do
    with {:ok, group} <- Groups.get_group(id),
         {:ok, group} <- Groups.update_group(group, args) do
      {:ok, %{success: true, group: group, errors: []}}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, %{success: false, group: nil, errors: format_errors(changeset)}}

      err ->
        err
    end
  end
end
