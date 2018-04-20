defmodule Level.Mutations do
  @moduledoc """
  Functions for performing GraphQL mutations.
  """

  alias Level.Groups
  alias Level.Posts
  alias Level.Spaces
  alias Level.Users.User

  @typedoc "A context map containing the current user"
  @type authenticated_context :: %{context: %{current_user: User.t()}}

  @typedoc "A list of validation errors"
  @type validation_errors :: [%{attribute: String.t(), message: String.t()}]

  @typedoc "The result of a group mutation"
  @type group_mutation_result ::
          {:ok, %{success: boolean(), group: Groups.Group.t() | nil, errors: validation_errors()}}
          | {:error, String.t()}

  @typedoc "The result of a post mutation"
  @type post_mutation_result ::
          {:ok, %{success: boolean(), post: Posts.Post.t() | nil, errors: validation_errors()}}
          | {:error, String.t()}

  @doc """
  Creates a new group.
  """
  @spec create_group(map(), authenticated_context()) :: group_mutation_result()
  def create_group(args, %{context: %{current_user: user}}) do
    resp =
      with {:ok, %{member: member}} <- Spaces.get_space_by_id(user, args.space_id),
           {:ok, %{group: group}} <- Groups.create_group(member, args) do
        %{success: true, group: group, errors: []}
      else
        {:error, :group, changeset, _} ->
          %{success: false, group: nil, errors: format_errors(changeset)}

        _ ->
          %{success: false, group: nil, errors: []}
      end

    {:ok, resp}
  end

  @doc """
  Updates a group.
  """
  @spec update_group(map(), authenticated_context()) :: group_mutation_result()
  def update_group(%{id: id} = args, %{context: %{current_user: user}}) do
    with {:ok, group} <- Groups.get_group(user, id),
         {:ok, group} <- Groups.update_group(group, args) do
      {:ok, %{success: true, group: group, errors: []}}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, %{success: false, group: nil, errors: format_errors(changeset)}}

      err ->
        err
    end
  end

  @doc """
  Creates a post.
  """
  @spec create_post(map(), authenticated_context()) :: post_mutation_result()
  def create_post(args, %{context: %{current_user: user}}) do
    case Posts.create_post(user, args) do
      {:ok, post} ->
        {:ok, %{success: true, post: post, errors: []}}

      {:error, changeset} ->
        {:ok, %{success: false, post: nil, errors: format_errors(changeset)}}
    end
  end

  defp format_errors(%Ecto.Changeset{errors: errors}) do
    Enum.map(errors, fn {attr, {msg, props}} ->
      message =
        Enum.reduce(props, msg, fn {k, v}, acc ->
          String.replace(acc, "%{#{k}}", to_string(v))
        end)

      %{attribute: attr, message: message}
    end)
  end
end
