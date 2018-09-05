defmodule Level.Mutations do
  @moduledoc """
  Functions for performing GraphQL mutations.
  """

  alias Level.Groups
  alias Level.Groups.GroupUser
  alias Level.Mentions
  alias Level.Posts
  alias Level.Spaces
  alias Level.Spaces.SpaceUser
  alias Level.Users
  alias Level.Users.User

  @typedoc "A context map containing the current user"
  @type info :: %{context: %{current_user: User.t()}}

  @typedoc "A list of validation errors"
  @type validation_errors :: [%{attribute: String.t(), message: String.t()}]

  @typedoc "The result of a user mutation"
  @type user_mutation_result ::
          {:ok, %{success: boolean(), user: Users.User.t() | nil, errors: validation_errors()}}
          | {:error, String.t()}

  @typedoc "The result of a space mutation"
  @type space_mutation_result ::
          {:ok, %{success: boolean(), space: Spaces.Space.t() | nil, errors: validation_errors()}}
          | {:error, String.t()}

  @typedoc "The result of a group mutation"
  @type group_mutation_result ::
          {:ok, %{success: boolean(), group: Groups.Group.t() | nil, errors: validation_errors()}}
          | {:error, String.t()}

  @typedoc "The payload for a bulk-created group"
  @type bulk_create_group_payload :: %{
          success: boolean(),
          args: %{name: String.t()},
          group: Groups.Group.t() | nil,
          errors: validation_errors
        }

  @typedoc "The payload for a group membership mutation"
  @type update_group_membership_payload ::
          {:ok, %{success: boolean(), membership: GroupUser.t(), errors: validation_errors()}}
          | {:error, String.t()}

  @typedoc "The payload for updating group bookmark state"
  @type bookmark_group_payload ::
          {:ok, %{is_bookmarked: boolean(), group: Groups.Group.t()}}
          | {:error, String.t()}

  @typedoc "The result of a bulk create group mutation"
  @type bulk_create_groups_result ::
          {:ok, %{payloads: [bulk_create_group_payload()]}} | {:error, String.t()}

  @typedoc "The result of a post mutation"
  @type post_mutation_result ::
          {:ok, %{success: boolean(), post: Posts.Post.t() | nil, errors: validation_errors()}}
          | {:error, String.t()}

  @typedoc "The result of a setup step mutation"
  @type setup_step_mutation_result ::
          {:ok, %{success: boolean(), state: atom()}} | {:error, String.t()}

  @typedoc "The args for creating a reply"
  @type new_reply_args :: %{space_id: String.t(), post_id: String.t(), body: String.t()}

  @typedoc "The result of a reply mutation"
  @type reply_mutation_result ::
          {:ok, %{success: boolean(), reply: Posts.Reply.t() | nil, errors: validation_errors()}}
          | {:error, String.t()}

  @doc """
  Updates a user's settings.
  """
  @spec update_user(map(), info()) :: user_mutation_result()
  def update_user(args, %{context: %{current_user: user}}) do
    case Users.update_user(user, args) do
      {:ok, user} ->
        {:ok, %{success: true, user: user, errors: []}}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, %{success: false, user: nil, errors: format_errors(changeset)}}

      err ->
        err
    end
  end

  @doc """
  Updates a user's avatar.
  """
  @spec update_user_avatar(map(), info()) :: user_mutation_result()
  def update_user_avatar(%{data: data}, %{context: %{current_user: user}}) do
    case Users.update_avatar(user, data) do
      {:ok, user} ->
        {:ok, %{success: true, user: user, errors: []}}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, %{success: false, user: nil, errors: format_errors(changeset)}}

      _ ->
        {:ok, %{success: false, user: nil, errors: []}}
    end
  end

  @doc """
  Creates a new space.
  """
  @spec create_space(map(), info()) :: space_mutation_result()
  def create_space(args, %{context: %{current_user: user}}) do
    resp =
      case Spaces.create_space(user, args) do
        {:ok, %{space: space}} ->
          %{success: true, space: space, errors: []}

        {:error, :space, changeset, _} ->
          %{success: false, space: nil, errors: format_errors(changeset)}

        _ ->
          %{success: false, space: nil, errors: []}
      end

    {:ok, resp}
  end

  @doc """
  Updates a space.
  """
  @spec update_space(map(), info()) :: space_mutation_result()
  def update_space(%{space_id: space_id} = args, %{context: %{current_user: user}}) do
    user
    |> Spaces.get_space(space_id)
    |> do_space_update(args)
    |> build_space_update_result()
  end

  defp do_space_update({:ok, %{space: space}}, args), do: Spaces.update_space(space, args)
  defp do_space_update(err, _args), do: err

  @doc """
  Updates a space's avatar.
  """
  @spec update_space_avatar(map(), info()) :: space_mutation_result()
  def update_space_avatar(%{space_id: space_id, data: data}, %{context: %{current_user: user}}) do
    user
    |> Spaces.get_space(space_id)
    |> do_space_avatar_update(data)
    |> build_space_update_result()
  end

  defp do_space_avatar_update({:ok, %{space: space}}, data) do
    Spaces.update_avatar(space, data)
  end

  defp do_space_avatar_update(err, _args), do: err

  defp build_space_update_result({:ok, space}) do
    {:ok, %{success: true, space: space, errors: []}}
  end

  defp build_space_update_result({:error, %Ecto.Changeset{} = changeset}) do
    {:ok, %{success: false, space: nil, errors: format_errors(changeset)}}
  end

  defp build_space_update_result(err), do: err

  @doc """
  Creates a new group.
  """
  @spec create_group(map(), info()) :: group_mutation_result()
  def create_group(args, %{context: %{current_user: user}}) do
    resp =
      with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, args.space_id),
           {:ok, %{group: group}} <- Groups.create_group(space_user, args) do
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
  @spec update_group(map(), info()) :: group_mutation_result()
  def update_group(args, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, args.space_id),
         {:ok, group} <- Groups.get_group(space_user, args.group_id),
         {:ok, updated_group} <- Groups.update_group(group, args) do
      {:ok, %{success: true, group: updated_group, errors: []}}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, %{success: false, group: nil, errors: format_errors(changeset)}}

      err ->
        err
    end
  end

  @doc """
  Create multiple groups.
  """
  @spec bulk_create_groups(map(), info()) :: bulk_create_groups_result()
  def bulk_create_groups(args, %{context: %{current_user: user}}) do
    case Spaces.get_space(user, args.space_id) do
      {:ok, %{space_user: space_user}} ->
        payloads =
          Enum.map(args.names, fn name ->
            bulk_create_group(space_user, name)
          end)

        {:ok, %{payloads: payloads}}

      err ->
        err
    end
  end

  @spec bulk_create_group(SpaceUser.t(), String.t()) :: bulk_create_group_payload()
  defp bulk_create_group(space_user, name) do
    args = %{name: name}

    case Groups.create_group(space_user, args) do
      {:ok, %{group: group}} ->
        %{success: true, group: group, errors: [], args: args}

      {:error, :group, changeset, _} ->
        %{success: false, group: nil, errors: format_errors(changeset), args: args}

      _ ->
        %{success: false, group: nil, errors: [], args: args}
    end
  end

  @doc """
  Updates a group membership.
  """
  @spec update_group_membership(map(), info()) :: update_group_membership_payload()
  def update_group_membership(args, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, args.space_id),
         {:ok, group} <- Groups.get_group(space_user, args.group_id),
         {:ok, %{group: updated_group, group_user: group_user}} <-
           Groups.update_group_membership(group, space_user, args.state) do
      {:ok, %{success: true, group: updated_group, membership: group_user, errors: []}}
    else
      {:error, %GroupUser{} = group_user, changeset} ->
        {:ok,
         %{success: false, group: nil, membership: group_user, errors: format_errors(changeset)}}

      err ->
        err
    end
  end

  @doc """
  Bookmarks a group.
  """
  @spec bookmark_group(map(), info()) :: bookmark_group_payload()
  def bookmark_group(args, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, args.space_id),
         {:ok, group} <- Groups.get_group(space_user, args.group_id),
         :ok <- Groups.bookmark_group(group, space_user) do
      {:ok, %{is_bookmarked: true, group: group}}
    else
      err ->
        err
    end
  end

  @doc """
  Unbookmarks a group.
  """
  @spec unbookmark_group(map(), info()) :: bookmark_group_payload()
  def unbookmark_group(args, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, args.space_id),
         {:ok, group} <- Groups.get_group(space_user, args.group_id),
         :ok <- Groups.unbookmark_group(group, space_user) do
      {:ok, %{is_bookmarked: false, group: group}}
    else
      err ->
        err
    end
  end

  @doc """
  Posts a message to a group.
  """
  @spec create_post(map(), info()) :: post_mutation_result()
  def create_post(args, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, args.space_id),
         {:ok, group} <- Groups.get_group(space_user, args.group_id),
         {:ok, %{post: post}} <- Posts.create_post(space_user, group, args) do
      {:ok, %{success: true, post: post, errors: []}}
    else
      {:error, :post, changeset, _} ->
        {:ok, %{success: false, post: nil, errors: format_errors(changeset)}}

      err ->
        err
    end
  end

  @doc """
  Marks a space setup step complete.
  """
  @spec complete_setup_step(map(), info()) :: setup_step_mutation_result()
  def complete_setup_step(args, %{context: %{current_user: user}}) do
    with {:ok, %{space: space, space_user: space_user}} <- Spaces.get_space(user, args.space_id),
         {:ok, next_state} <- Spaces.complete_setup_step(space_user, space, args) do
      {:ok, %{success: true, state: next_state}}
    else
      err ->
        err
    end
  end

  @doc """
  Creates a reply on a post.
  """
  @spec create_reply(new_reply_args(), info()) :: reply_mutation_result()
  def create_reply(%{space_id: space_id, post_id: post_id} = args, %{
        context: %{current_user: user}
      }) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, space_id),
         {:ok, post} <- Posts.get_post(space_user, post_id),
         {:ok, %{reply: reply}} <- Posts.create_reply(space_user, post, args) do
      {:ok, %{success: true, reply: reply, errors: []}}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, %{success: false, reply: nil, errors: format_errors(changeset)}}

      err ->
        err
    end
  end

  @doc """
  Records a post view.
  """
  @spec record_post_view(map(), info()) ::
          {:ok, %{success: boolean(), errors: validation_errors()}} | {:error, String.t()}

  def record_post_view(
        %{space_id: space_id, post_id: post_id},
        %{context: %{current_user: user}}
      ) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, space_id),
         {:ok, post} <- Posts.get_post(space_user, post_id),
         {:ok, _} <- Posts.record_view(post, space_user) do
      {:ok, %{success: true, errors: []}}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, %{success: false, errors: format_errors(changeset)}}

      err ->
        err
    end
  end

  def record_post_view(
        %{space_id: space_id, post_id: post_id, last_viewed_reply_id: reply_id},
        %{context: %{current_user: user}}
      ) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, space_id),
         {:ok, post} <- Posts.get_post(space_user, post_id),
         {:ok, reply} <- Posts.get_reply(post, reply_id),
         {:ok, _} <- Posts.record_view(post, space_user, reply) do
      {:ok, %{success: true, errors: []}}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, %{success: false, errors: format_errors(changeset)}}

      err ->
        err
    end
  end

  @doc """
  Dismisses all mentions for a particular post.
  """
  @spec dismiss_mentions(map(), info()) ::
          {:ok, %{success: boolean(), posts: [Post.t()] | nil, errors: validation_errors()}}
          | {:error, String.t()}
  def dismiss_mentions(
        %{space_id: space_id, post_ids: post_ids},
        %{context: %{current_user: user}}
      ) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, space_id),
         {:ok, posts} <- Mentions.dismiss_all(space_user, post_ids) do
      {:ok, %{success: true, posts: posts, errors: []}}
    else
      err ->
        err
    end
  end

  @doc """
  Dismisses all mentions for a particular post.
  """
  @spec dismiss_posts(map(), info()) ::
          {:ok, %{success: boolean(), posts: [Post.t()] | nil, errors: validation_errors()}}
          | {:error, String.t()}
  def dismiss_posts(
        %{space_id: space_id, post_ids: post_ids},
        %{context: %{current_user: user}}
      ) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, space_id),
         {:ok, posts} <- Posts.get_posts(user, post_ids),
         {:ok, dismissed_posts} <- Posts.dismiss(space_user, posts) do
      {:ok, %{success: true, posts: dismissed_posts, errors: []}}
    else
      err ->
        err
    end
  end

  defp format_errors(%Ecto.Changeset{errors: errors}) do
    Enum.map(errors, fn {attr, {msg, props}} ->
      message =
        Enum.reduce(props, msg, fn {k, v}, acc ->
          String.replace(acc, "%{#{k}}", to_string(v))
        end)

      attribute =
        attr
        |> Atom.to_string()
        |> Absinthe.Utils.camelize(lower: true)

      %{attribute: attribute, message: message}
    end)
  end
end
