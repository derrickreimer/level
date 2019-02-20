defmodule LevelWeb.Schema.Objects do
  @moduledoc false

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  alias Level.AssetStore
  alias Level.Files
  alias Level.Groups
  alias Level.Posts
  alias Level.Resolvers
  alias Level.Schemas.GroupBookmark
  alias Level.Schemas.GroupUser
  alias Level.Schemas.Post
  alias Level.Schemas.Reply
  alias Level.Schemas.SearchResult
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser
  alias Level.Spaces
  alias LevelWeb.Endpoint
  alias LevelWeb.Router.Helpers

  import_types LevelWeb.Schema.Enums
  import_types LevelWeb.Schema.Scalars
  import_types LevelWeb.Schema.InputObjects

  @desc """
  Interface for objects containg a `fetched_at` field corresponding with
  the time at which the object was fetched from the database. This field
  can be used to compare freshness between two copies of the same object.
  """
  interface :fetch_timeable do
    field :fetched_at, non_null(:timestamp)
    resolve_type fn _, _ -> nil end
  end

  @desc "A user represents a person belonging to a specific space."
  object :user do
    field :id, non_null(:id)
    field :state, non_null(:user_state)
    field :email, non_null(:string)
    field :first_name, non_null(:string)
    field :last_name, non_null(:string)
    field :handle, non_null(:string)
    field :time_zone, :string
    field :inserted_at, non_null(:timestamp)
    field :updated_at, non_null(:timestamp)

    field :space_users, non_null(:space_user_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :space_user_order
      resolve &Resolvers.space_users/3
    end

    field :group_memberships, non_null(:group_user_connection) do
      arg :space_id, non_null(:id)
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :group_order
      resolve &Resolvers.group_memberships/3
    end

    field :avatar_url, :string do
      resolve fn user, _, _ ->
        if user.avatar do
          {:ok, AssetStore.avatar_url(user.avatar)}
        else
          {:ok, nil}
        end
      end
    end

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp), resolve: fetch_time()
  end

  @desc "A space user defines a user's identity within a particular space."
  object :space_user do
    field :id, non_null(:id)
    field :user_id, non_null(:id)
    field :state, non_null(:space_user_state)
    field :role, non_null(:space_user_role)
    field :space, non_null(:space), resolve: dataloader(:db)
    field :first_name, non_null(:string)
    field :last_name, non_null(:string)
    field :handle, non_null(:string)

    field :digest_settings, :digest_settings do
      resolve fn space_user, _, %{context: %{current_user: user}} ->
        if space_user.user_id == user.id do
          {:ok, %{is_enabled: space_user.is_digest_enabled}}
        else
          {:ok, nil}
        end
      end
    end

    field :tutorial, :tutorial do
      arg :key, non_null(:string)

      resolve &Resolvers.tutorial/3
    end

    field :nudges, list_of(:nudge) do
      resolve &Resolvers.nudges/3
    end

    field :bookmarks, list_of(:group) do
      resolve fn space_user, _args, %{context: %{current_user: user}} ->
        if space_user.user_id == user.id do
          {:ok, Groups.list_bookmarks(space_user)}
        else
          {:ok, nil}
        end
      end
    end

    field :avatar_url, :string do
      resolve fn space_user, _, _ ->
        if space_user.avatar do
          {:ok, AssetStore.avatar_url(space_user.avatar)}
        else
          {:ok, nil}
        end
      end
    end

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp), resolve: fetch_time()

    # Permissions

    @desc "Determines whether the user is allowed to manage members."
    field :can_manage_members, non_null(:boolean) do
      resolve &Resolvers.can_manage_members?/3
    end

    @desc "Determines whether the user is allowed to manage owners."
    field :can_manage_owners, non_null(:boolean) do
      resolve &Resolvers.can_manage_owners?/3
    end
  end

  @desc "A time of day at which to nudge a user."
  object :nudge do
    field :id, non_null(:id)
    field :minute, non_null(:integer)
  end

  @desc "Describes a user's digest sending preferences."
  object :digest_settings do
    field :is_enabled, non_null(:boolean)
  end

  @desc "A space bot represents a bot that has been installed in a particular space."
  object :space_bot do
    field :id, non_null(:id)
    field :space, non_null(:space), resolve: dataloader(:db)
    field :display_name, non_null(:string)
    field :handle, non_null(:string)

    field :avatar_url, :string do
      resolve fn space_bot, _, _ ->
        cond do
          space_bot.handle == "levelbot" ->
            {:ok,
             LevelWeb.Router.Helpers.static_url(LevelWeb.Endpoint, "/images/avatar-light.png")}

          space_bot.avatar ->
            {:ok, AssetStore.avatar_url(space_bot.avatar)}

          true ->
            {:ok, nil}
        end
      end
    end

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp), resolve: fetch_time()
  end

  @desc "A space represents a company or organization."
  object :space do
    field :id, non_null(:id)
    field :state, non_null(:space_state)
    field :name, non_null(:string)
    field :slug, non_null(:string)
    field :inserted_at, non_null(:timestamp)
    field :updated_at, non_null(:timestamp)

    field :avatar_url, :string do
      resolve fn space, _, _ ->
        if space.avatar do
          {:ok, AssetStore.avatar_url(space.avatar)}
        else
          {:ok, nil}
        end
      end
    end

    field :setup_state, non_null(:space_setup_state) do
      resolve fn space, _args, _context ->
        Spaces.get_setup_state(space)
      end
    end

    @desc "The currently active open invitation URL for the space."
    field :open_invitation_url, :string do
      resolve fn space, _args, _context ->
        case Spaces.get_open_invitation(space) do
          {:ok, invitation} ->
            {:ok, Helpers.open_invitation_url(Endpoint, :show, invitation.token)}

          :revoked ->
            {:ok, nil}
        end
      end
    end

    @desc "The postbot URL."
    field :postbot_url, :string do
      resolve fn space, _args, _context ->
        {:ok, Helpers.postbot_url(Endpoint, :create, space, space.postbot_key)}
      end
    end

    @desc "A paginated list of groups in the space."
    field :groups, non_null(:group_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :group_order
      arg :state, :group_state_filter, default_value: :open
      resolve &Resolvers.groups/3
    end

    @desc "Fetch a post by id."
    field :post, :post do
      arg :id, non_null(:id)
      resolve &Resolvers.post/3
    end

    @desc "A preview of space users (for display in the directory sidebar)."
    field :featured_users, list_of(:space_user) do
      resolve &Resolvers.featured_space_users/3
    end

    @desc "A paginated list of users in the space."
    field :space_users, non_null(:space_user_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :space_user_order
      resolve &Resolvers.space_users/3
    end

    @desc "A paginated list of posts ."
    field :posts, non_null(:post_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :timestamp
      arg :after, :timestamp

      @desc "Filtering criteria for posts."
      arg :filter, :post_filters

      resolve &Resolvers.posts/3
    end

    @desc "A paginated list of search results."
    field :search, non_null(:search_connection) do
      arg :page, :integer, default_value: 1
      arg :count, :integer, default_value: 20
      arg :query, non_null(:string)

      resolve &Resolvers.search/3
    end

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp), resolve: fetch_time()

    # Viewer-contextual fields

    @desc "Determines whether the current user is allowed to update the space."
    field :can_update, non_null(:boolean) do
      resolve &Resolvers.can_update?/3
    end
  end

  @desc "A group is a collection of users within a space."
  object :group do
    field :id, non_null(:id)
    field :state, non_null(:group_state)
    field :name, non_null(:string)
    field :description, :string
    field :is_private, non_null(:boolean)
    field :inserted_at, non_null(:timestamp)
    field :updated_at, non_null(:timestamp)
    field :space, non_null(:space), resolve: dataloader(:db)
    field :creator, non_null(:user), resolve: dataloader(:db)

    @desc "Determines whether the users are automatically subscribed to the group when they join."
    field :is_default, non_null(:boolean)

    @desc "Posts sent to the group."
    field :posts, non_null(:post_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :timestamp
      arg :after, :timestamp

      @desc "Filtering criteria for posts."
      arg :filter, :post_filters

      resolve &Resolvers.posts/3
    end

    @desc "A paginated connection of group memberships."
    field :memberships, non_null(:group_user_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :user_order
      resolve &Resolvers.group_memberships/3
    end

    @desc "The short list of members to display in the sidebar."
    field :featured_memberships, list_of(:group_user) do
      resolve &Resolvers.featured_group_memberships/3
    end

    @desc "Member with group ownership rights."
    field :owners, list_of(:group_user) do
      resolve fn group, _, _ ->
        Groups.list_all_owners(group)
      end
    end

    @desc "Members who have been granted private access."
    field :private_accessors, list_of(:group_user) do
      resolve fn group, _, _ ->
        Groups.list_all_with_private_access(group)
      end
    end

    # Viewer-contextual fields

    @desc "The current user's group membership."
    field :membership, :group_user do
      resolve fn group, _, %{context: %{loader: loader}} ->
        dataloader_with_handler(%{
          loader: loader,
          source_name: :db,
          batch_key: {:one, GroupUser},
          item_key: [group_id: group.id],
          handler_fn: fn record -> {:ok, record} end
        })
      end
    end

    @desc "The bookmarking state of the current user."
    field :is_bookmarked, non_null(:boolean) do
      resolve fn group, _, %{context: %{loader: loader}} ->
        dataloader_with_handler(%{
          loader: loader,
          source_name: :db,
          batch_key: {:one, GroupBookmark},
          item_key: [group_id: group.id],
          handler_fn: fn
            %GroupBookmark{} -> {:ok, true}
            _ -> {:ok, false}
          end
        })
      end
    end

    @desc "Determines if the current user is allowed to manage group permissions."
    field :can_manage_permissions, non_null(:boolean) do
      resolve fn group, _, %{context: %{loader: loader}} ->
        dataloader_with_handler(%{
          loader: loader,
          source_name: :db,
          batch_key: {:one, GroupUser},
          item_key: [group_id: group.id],
          handler_fn: &Groups.can_manage_permissions?/1
        })
      end
    end

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp), resolve: fetch_time()
  end

  @desc "A group membership defines the relationship between a user and group."
  object :group_user do
    field :group, non_null(:group), resolve: dataloader(:db)
    field :space_user, non_null(:space_user), resolve: dataloader(:db)
    field :state, non_null(:group_membership_state)
    field :role, non_null(:group_role)
    field :access, non_null(:group_access)

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp), resolve: fetch_time()
  end

  @desc "A post represents a conversation."
  object :post do
    field :id, non_null(:id)
    field :state, non_null(:post_state)
    field :body, non_null(:string)
    field :space, non_null(:space), resolve: dataloader(:db)
    field :groups, list_of(:group), resolve: dataloader(:db)

    field :author, non_null(:author) do
      resolve &Resolvers.post_author/3
    end

    field :body_html, non_null(:string) do
      resolve &Resolvers.render_markdown/3
    end

    field :posted_at, non_null(:timestamp) do
      resolve fn post, _, _ ->
        {:ok, post.inserted_at}
      end
    end

    field :replies, non_null(:reply_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :reply_order
      resolve &Resolvers.replies/3
    end

    field :reactions, non_null(:post_reaction_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :reaction_order
      resolve &Resolvers.reactions/3
    end

    field :files, list_of(:file), resolve: dataloader(:db)

    field :is_private, non_null(:boolean) do
      resolve fn post, _, _ ->
        Posts.private?(post)
      end
    end

    field :last_activity_at, non_null(:timestamp) do
      resolve fn
        %Post{last_activity_at: last_activity_at}, _, _ when not is_nil(last_activity_at) ->
          {:ok, last_activity_at}

        post, _, _ ->
          Posts.last_activity_at(post)
      end
    end

    # Viewer-contextual fields
    @desc "The viewer's subscription to the post."
    field :subscription_state, non_null(:post_subscription_state) do
      resolve &Resolvers.subscription_state/3
    end

    @desc "The viewer's inbox state for the post."
    field :inbox_state, non_null(:inbox_state) do
      resolve &Resolvers.inbox_state/3
    end

    @desc "A list of mentions for the current viewer."
    field :mentions, list_of(:mention) do
      resolve &Resolvers.mentions/3
    end

    @desc "Determines if the viewer is eligible to edit the post."
    field :can_edit, non_null(:boolean) do
      resolve &Resolvers.can_edit_post/3
    end

    @desc "Determines whether the current viewer has reacted to the reply."
    field :has_reacted, non_null(:boolean) do
      resolve &Resolvers.has_reacted/3
    end

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp), resolve: fetch_time()
  end

  @desc "A reply represents a response to a post."
  object :reply do
    field :id, non_null(:id)
    field :post_id, non_null(:id)
    field :body, non_null(:string)
    field :space, non_null(:space), resolve: dataloader(:db)
    field :is_deleted, non_null(:boolean)

    field :author, non_null(:author) do
      resolve &Resolvers.reply_author/3
    end

    field :body_html, non_null(:string) do
      resolve &Resolvers.render_markdown/3
    end

    field :posted_at, non_null(:timestamp) do
      resolve fn reply, _, _ ->
        {:ok, reply.inserted_at}
      end
    end

    field :reactions, non_null(:reply_reaction_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :reaction_order
      resolve &Resolvers.reactions/3
    end

    field :files, list_of(:file), resolve: dataloader(:db)

    # Viewer-contextual fields

    @desc "Determines whether the current viewer has viewed the reply."
    field :has_viewed, non_null(:boolean) do
      resolve &Resolvers.has_viewed_reply/3
    end

    @desc "Determines whether the current viewer has reacted to the reply."
    field :has_reacted, non_null(:boolean) do
      resolve &Resolvers.has_reacted/3
    end

    @desc "Determines if the viewer is eligible to edit the reply."
    field :can_edit, non_null(:boolean) do
      resolve &Resolvers.can_edit_reply/3
    end

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp), resolve: fetch_time()
  end

  @desc "Represents a user's reaction to a post."
  object :post_reaction do
    field :space_user, non_null(:space_user), resolve: dataloader(:db)
    field :post, non_null(:post), resolve: dataloader(:db)
  end

  @desc "Represents a user's reaction to a reply."
  object :reply_reaction do
    field :space_user, non_null(:space_user), resolve: dataloader(:db)
    field :post, non_null(:post), resolve: dataloader(:db)
    field :reply, non_null(:reply), resolve: dataloader(:db)
  end

  @desc "A mention represents a when user has @-mentioned another user."
  object :mention do
    field :mentioner, non_null(:space_user), resolve: dataloader(:db)
    field :reply, :reply, resolve: dataloader(:db)
    field :occurred_at, non_null(:timestamp)
  end

  @desc "A file upload."
  object :file do
    field :id, non_null(:id)
    field :content_type, :string
    field :filename, non_null(:string)
    field :size, non_null(:integer)

    field :url, non_null(:string) do
      resolve fn file, _, _ ->
        {:ok, Files.file_url(file)}
      end
    end

    field :inserted_at, non_null(:timestamp)

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp), resolve: fetch_time()
  end

  @desc "A user's relationship with a tutorial."
  object :tutorial do
    field :key, non_null(:string)
    field :current_step, non_null(:integer)
    field :is_complete, non_null(:boolean)
    field :space_user, non_null(:space_user), resolve: dataloader(:db)
  end

  @desc "An author of a message."
  object :author do
    field :actor, non_null(:actor)
    field :overrides, non_null(:author_overrides)
  end

  @desc "Overriding values for author attributes."
  object :author_overrides do
    field :display_name, :string
    field :initials, :string
    field :avatar_color, :string
  end

  @desc "An actor."
  union :actor do
    types [:space_user, :space_bot]

    resolve_type fn
      %SpaceUser{}, _ -> :space_user
      %SpaceBot{}, _ -> :space_bot
    end
  end

  @desc "A search result."
  union :search_result do
    types [:post_search_result, :reply_search_result]

    resolve_type fn
      %SearchResult{searchable_type: "Post"}, _ -> :post_search_result
      %SearchResult{searchable_type: "Reply"}, _ -> :reply_search_result
    end
  end

  @desc "A post search result."
  object :post_search_result do
    field :preview, non_null(:string)

    # For some strange reason, dataloader(:db) helper is producing
    # flat out incorrect results.
    #
    # field :post, non_null(:post), resolve: dataloader(:db)
    field :post, non_null(:post) do
      resolve fn parent, _, %{context: %{loader: loader}} ->
        loader
        |> Dataloader.load(:db, Post, parent.post_id)
        |> on_load(fn loader ->
          {:ok, Dataloader.get(loader, :db, Post, parent.post_id)}
        end)
      end
    end
  end

  @desc "A reply search result."
  object :reply_search_result do
    field :preview, non_null(:string)

    # For some strange reason, dataloader(:db) helper is producing
    # flat out incorrect results.
    #
    # field :post, non_null(:post), resolve: dataloader(:db)
    field :post, non_null(:post) do
      resolve fn parent, _, %{context: %{loader: loader}} ->
        loader
        |> Dataloader.load(:db, Post, parent.post_id)
        |> on_load(fn loader ->
          {:ok, Dataloader.get(loader, :db, Post, parent.post_id)}
        end)
      end
    end

    field :reply, non_null(:reply) do
      resolve fn parent, _, %{context: %{loader: loader}} ->
        loader
        |> Dataloader.load(:db, Reply, parent.searchable_id)
        |> on_load(fn loader ->
          {:ok, Dataloader.get(loader, :db, Reply, parent.searchable_id)}
        end)
      end
    end
  end

  def fetch_time do
    fn _, _ ->
      {:ok, DateTime.utc_now()}
    end
  end

  def dataloader_with_handler(args) do
    args.loader
    |> Dataloader.load(args.source_name, args.batch_key, args.item_key)
    |> on_load(fn loader ->
      loader
      |> Dataloader.get(args.source_name, args.batch_key, args.item_key)
      |> args.handler_fn.()
    end)
  end
end
