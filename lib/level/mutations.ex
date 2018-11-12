defmodule Level.Mutations do
  @moduledoc """
  Functions for performing GraphQL mutations.
  """

  import Level.Gettext

  alias Level.Groups
  alias Level.Mentions
  alias Level.Posts
  alias Level.Schemas.User
  alias Level.Spaces
  alias Level.Users

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

  @typedoc "The payload for the subscribe to group mutation"
  @type subscribe_to_group_payload ::
          {:ok, %{success: boolean(), group: Group.t(), errors: validation_errors()}}
          | {:error, String.t()}

  @typedoc "The payload for the unsubscribe from group mutation"
  @type unsubscribe_from_group_payload ::
          {:ok, %{success: boolean(), group: Group.t(), errors: validation_errors()}}
          | {:error, String.t()}

  @typedoc "The payload for the grant group access mutation"
  @type grant_group_access_payload ::
          {:ok, %{success: boolean(), errors: validation_errors()}}
          | {:error, String.t()}

  @typedoc "The payload for the revoke group access mutation"
  @type revoke_group_access_payload ::
          {:ok, %{success: boolean(), errors: validation_errors()}}
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
    |> authorize_update_space()
    |> do_space_update(args)
    |> build_space_update_result()
  end

  defp authorize_update_space({:ok, %{space_user: space_user}} = result) do
    if Spaces.can_update?(space_user) do
      result
    else
      {:error, dgettext("errors", "You are not authorized to perform this action.")}
    end
  end

  defp authorize_update_space(err), do: err

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
        {:error, changeset} ->
          %{success: false, group: nil, errors: format_errors(changeset)}
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
  Closes a group.
  """
  @spec close_group(map(), info()) :: group_mutation_result()
  def close_group(args, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, args.space_id),
         {:ok, group} <- Groups.get_group(space_user, args.group_id),
         {:ok, updated_group} <- Groups.close_group(group) do
      {:ok, %{success: true, group: updated_group, errors: []}}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, %{success: false, group: nil, errors: format_errors(changeset)}}

      err ->
        err
    end
  end

  @doc """
  Reopens a group.
  """
  @spec reopen_group(map(), info()) :: group_mutation_result()
  def reopen_group(args, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, args.space_id),
         {:ok, group} <- Groups.get_group(space_user, args.group_id),
         {:ok, updated_group} <- Groups.reopen_group(group) do
      {:ok, %{success: true, group: updated_group, errors: []}}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, %{success: false, group: nil, errors: format_errors(changeset)}}

      err ->
        err
    end
  end

  @doc """
  Deletes a group.
  """
  @spec delete_group(map(), info()) :: group_mutation_result()
  def delete_group(args, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, args.space_id),
         {:ok, group} <- Groups.get_group(space_user, args.group_id),
         {:ok, _} <- Groups.delete_group(space_user, group) do
      {:ok, %{success: true, errors: []}}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, %{success: false, errors: format_errors(changeset)}}

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

  defp bulk_create_group(space_user, name) do
    args = %{name: name}

    case Groups.create_group(space_user, args) do
      {:ok, %{group: group}} ->
        %{success: true, group: group, errors: [], args: args}

      {:error, changeset} ->
        %{success: false, group: nil, errors: format_errors(changeset), args: args}
    end
  end

  @doc """
  Subscribes to a group.
  """
  @spec subscribe_to_group(map(), info()) :: subscribe_to_group_payload()
  def subscribe_to_group(args, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, args.space_id),
         {:ok, group} <- Groups.get_group(space_user, args.group_id),
         :ok <- Groups.subscribe(group, space_user) do
      {:ok, %{success: true, group: group, errors: []}}
    else
      err ->
        err
    end
  end

  @doc """
  Unsubscribes from a group.
  """
  @spec unsubscribe_from_group(map(), info()) :: unsubscribe_from_group_payload()
  def unsubscribe_from_group(args, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, args.space_id),
         {:ok, group} <- Groups.get_group(space_user, args.group_id),
         :ok <- Groups.unsubscribe(group, space_user) do
      {:ok, %{success: true, group: group, errors: []}}
    else
      err ->
        err
    end
  end

  @doc """
  Grants a user access to a group.
  """
  @spec grant_group_access(map(), info()) :: grant_group_access_payload()
  def grant_group_access(args, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, args.space_id),
         {:ok, group} <- Groups.get_group(space_user, args.group_id),
         {:ok, space_user} <- Spaces.get_space_user(user, args.space_user_id),
         :ok <- Groups.grant_access(user, group, space_user) do
      {:ok, %{success: true, errors: []}}
    else
      err ->
        err
    end
  end

  @doc """
  Revokes a user's access to a group.
  """
  @spec revoke_group_access(map(), info()) :: revoke_group_access_payload()
  def revoke_group_access(args, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, args.space_id),
         {:ok, group} <- Groups.get_group(space_user, args.group_id),
         {:ok, space_user} <- Spaces.get_space_user(user, args.space_user_id),
         :ok <- Groups.revoke_access(user, group, space_user) do
      {:ok, %{success: true, errors: []}}
    else
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
  Updates a post.
  """
  @spec update_post(map(), info()) :: post_mutation_result()
  def update_post(args, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, args.space_id),
         {:ok, post} <- Posts.get_post(user, args.post_id),
         {:ok, %{updated_post: updated_post}} <- Posts.update_post(space_user, post, args) do
      {:ok, %{success: true, post: updated_post, errors: []}}
    else
      {:error, :original_post, _, _} ->
        {:ok, %{success: false, post: nil, errors: []}}

      {:error, :updated_post, changeset, _} ->
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
      {:error, :reply, %Ecto.Changeset{} = changeset, _} ->
        {:ok, %{success: false, reply: nil, errors: format_errors(changeset)}}

      err ->
        err
    end
  end

  @doc """
  Updates a reply.
  """
  @spec update_reply(map(), info()) :: reply_mutation_result()
  def update_reply(args, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, args.space_id),
         {:ok, reply} <- Posts.get_reply(user, args.reply_id),
         {:ok, %{updated_reply: updated_reply}} <- Posts.update_reply(space_user, reply, args) do
      {:ok, %{success: true, reply: updated_reply, errors: []}}
    else
      {:error, :original_reply, _, _} ->
        {:ok, %{success: false, reply: nil, errors: []}}

      {:error, :updated_reply, changeset, _} ->
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
          {:ok, %{success: boolean(), posts: [Posts.Post.t()] | nil, errors: validation_errors()}}
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
  Dismisses posts from the inbox.
  """
  @spec dismiss_posts(map(), info()) ::
          {:ok, %{success: boolean(), posts: [Posts.Post.t()] | nil, errors: validation_errors()}}
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

  @doc """
  Marks posts as unread.
  """
  @spec mark_as_unread(map(), info()) ::
          {:ok, %{success: boolean(), posts: [Posts.Post.t()] | nil, errors: validation_errors()}}
          | {:error, String.t()}
  def mark_as_unread(
        %{space_id: space_id, post_ids: post_ids},
        %{context: %{current_user: user}}
      ) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, space_id),
         {:ok, posts} <- Posts.get_posts(user, post_ids),
         {:ok, unread_posts} <- Posts.mark_as_unread(space_user, posts) do
      {:ok, %{success: true, posts: unread_posts, errors: []}}
    else
      err ->
        err
    end
  end

  @doc """
  Marks posts as read.
  """
  @spec mark_as_read(map(), info()) ::
          {:ok, %{success: boolean(), posts: [Posts.Post.t()] | nil, errors: validation_errors()}}
          | {:error, String.t()}
  def mark_as_read(
        %{space_id: space_id, post_ids: post_ids},
        %{context: %{current_user: user}}
      ) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, space_id),
         {:ok, posts} <- Posts.get_posts(user, post_ids),
         {:ok, read_posts} <- Posts.mark_as_read(space_user, posts) do
      {:ok, %{success: true, posts: read_posts, errors: []}}
    else
      err ->
        err
    end
  end

  @doc """
  Registers a push subscription.
  """
  @spec register_push_subscription(map(), info()) ::
          {:ok, %{success: boolean(), errors: validation_errors()}}
  def register_push_subscription(%{data: data}, %{context: %{current_user: user}}) do
    case Users.create_push_subscription(user, data) do
      {:ok, _} ->
        {:ok, %{success: true, errors: []}}

      {:error, _} ->
        {:ok, %{success: false, errors: []}}
    end
  end

  @doc """
  Records reply views.
  """
  @spec record_reply_views(map(), info()) ::
          {:ok, %{success: boolean(), errors: validation_errors(), replies: [Reply.t()]}}
          | {:error, String.t()}
  def record_reply_views(%{space_id: space_id, reply_ids: reply_ids}, %{
        context: %{current_user: user}
      }) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, space_id),
         {:ok, fetched_replies} <- Posts.get_replies(user, reply_ids),
         {:ok, replies} <- Posts.record_reply_views(space_user, fetched_replies) do
      {:ok, %{success: true, errors: [], replies: replies}}
    else
      _ ->
        {:ok, %{success: false, errors: []}}
    end
  end

  @doc """
  Closes a post.
  """
  @spec close_post(map, info()) ::
          {:ok, %{success: boolean(), errors: validation_errors(), post: Post.t()}}
          | {:error, String.t()}
  def close_post(%{space_id: space_id, post_id: post_id}, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, space_id),
         {:ok, post} <- Posts.get_post(user, post_id),
         {:ok, %{post: closed_post}} <- Posts.close_post(space_user, post) do
      {:ok, %{success: true, errors: [], post: closed_post}}
    else
      err ->
        err
    end
  end

  @doc """
  Reopens a post.
  """
  @spec reopen_post(map, info()) ::
          {:ok, %{success: boolean(), errors: validation_errors(), post: Post.t()}}
          | {:error, String.t()}
  def reopen_post(%{space_id: space_id, post_id: post_id}, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, space_id),
         {:ok, post} <- Posts.get_post(user, post_id),
         {:ok, %{post: reopened_post}} <- Posts.reopen_post(space_user, post) do
      {:ok, %{success: true, errors: [], post: reopened_post}}
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
