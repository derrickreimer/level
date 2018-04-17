defmodule Level.Mutations do
  @moduledoc """
  Functions for performing GraphQL mutations.
  """

  import Level.Gettext

  alias Level.Groups
  alias Level.Posts
  alias Level.Repo
  alias Level.Spaces
  alias Level.Spaces.User

  @typedoc "A context map containing the current user"
  @type authenticated_context :: %{context: %{current_user: User.t()}}

  @typedoc "A list of validation errors"
  @type validation_errors :: [%{attribute: String.t(), message: String.t()}]

  @typedoc "The result of an invitation mutation"
  @type invitation_mutation_result ::
          {:ok,
           %{
             success: boolean(),
             invitation: Spaces.Invitation.t() | nil,
             errors: validation_errors()
           }}

  @typedoc "The result of a group mutation"
  @type group_mutation_result ::
          {:ok, %{success: boolean(), group: Groups.Group.t() | nil, errors: validation_errors()}}
          | {:error, String.t()}

  @typedoc "The result of a post mutation"
  @type post_mutation_result ::
          {:ok, %{success: boolean(), post: Posts.Post.t() | nil, errors: validation_errors()}}
          | {:error, String.t()}

  @doc """
  Creates a new invitation.
  """
  @spec create_invitation(map(), authenticated_context()) :: invitation_mutation_result()
  def create_invitation(args, %{context: %{current_user: user}}) do
    resp =
      case Spaces.create_invitation(user, args) do
        {:ok, invitation} ->
          %{success: true, invitation: invitation, errors: []}

        {:error, changeset} ->
          %{success: false, invitation: nil, errors: format_errors(changeset)}
      end

    {:ok, resp}
  end

  @doc """
  Revokes an invitation.
  """
  @spec revoke_invitation(map(), authenticated_context()) :: invitation_mutation_result()
  def revoke_invitation(args, %{context: %{current_user: user}}) do
    user = Repo.preload(user, :space)

    resp =
      case Spaces.get_pending_invitation(user.space, args.id) do
        nil ->
          %{
            success: false,
            invitation: nil,
            errors: [
              %{
                attribute: "base",
                message: dgettext("errors", "Invitation not found")
              }
            ]
          }

        invitation ->
          case Spaces.revoke_invitation(invitation) do
            {:ok, _} ->
              %{success: true, invitation: invitation, errors: []}

            {:error, _} ->
              %{success: false, invitation: invitation, errors: []}
          end
      end

    {:ok, resp}
  end

  @doc """
  Creates a new group.
  """
  @spec create_group(map(), authenticated_context()) :: group_mutation_result()
  def create_group(args, %{context: %{current_user: user}}) do
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
