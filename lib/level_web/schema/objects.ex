defmodule LevelWeb.Schema.Objects do
  @moduledoc false

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  alias Level.AssetStore
  alias Level.Groups
  alias Level.Posts
  alias Level.Resolvers
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
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :space_users, non_null(:space_user_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :space_user_order
      resolve &Resolvers.space_users/3
    end

    field :group_memberships, non_null(:group_membership_connection) do
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
        {:ok, AssetStore.avatar_url(user)}
      end
    end

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp) do
      resolve &fetched_at_resolver/2
    end
  end

  @desc "A space user defines a user's identity within a particular space."
  object :space_user do
    field :id, non_null(:id)
    field :state, non_null(:space_user_state)
    field :role, non_null(:space_user_role)
    field :space, non_null(:space), resolve: dataloader(Spaces)
    field :first_name, non_null(:string)
    field :last_name, non_null(:string)
    field :handle, non_null(:string)

    @desc "A list of groups the user has bookmarked."
    field :bookmarked_groups, list_of(:group) do
      resolve fn space_user, _args, %{context: %{current_user: user}} ->
        if space_user.user_id == user.id do
          {:ok, Groups.list_bookmarked_groups(space_user)}
        else
          {:ok, nil}
        end
      end
    end

    field :avatar_url, :string do
      resolve fn space_user, _, _ ->
        {:ok, AssetStore.avatar_url(space_user)}
      end
    end

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp) do
      resolve &fetched_at_resolver/2
    end
  end

  @desc "A space represents a company or organization."
  object :space do
    field :id, non_null(:id)
    field :state, non_null(:space_state)
    field :name, non_null(:string)
    field :slug, non_null(:string)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :avatar_url, :string do
      resolve fn space, _, _ ->
        {:ok, AssetStore.avatar_url(space)}
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

    @desc "A paginated list of groups in the space."
    field :groups, non_null(:group_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :group_order
      arg :state, :group_state
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

    @desc "A paginated list of posts for which the current user has undismissed mentions."
    field :mentioned_posts, non_null(:post_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :mentioned_post_order
      resolve &Resolvers.mentioned_posts/3
    end

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp) do
      resolve &fetched_at_resolver/2
    end
  end

  @desc "A group is a collection of users within a space."
  object :group do
    field :id, non_null(:id)
    field :state, non_null(:group_state)
    field :name, non_null(:string)
    field :description, :string
    field :is_private, non_null(:boolean)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)
    field :space, non_null(:space), resolve: dataloader(Spaces)
    field :creator, non_null(:user), resolve: dataloader(:db)

    @desc "Posts sent to the group."
    field :posts, non_null(:post_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :post_order
      resolve &Resolvers.group_posts/3
    end

    @desc "A paginated connection of group memberships."
    field :memberships, non_null(:group_membership_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :user_order
      resolve &Resolvers.group_memberships/3
    end

    @desc "The current user's group membership."
    field :membership, :group_membership do
      resolve &Resolvers.group_membership/3
    end

    @desc "The short list of members to display in the sidebar."
    field :featured_memberships, list_of(:group_membership) do
      resolve &Resolvers.featured_group_memberships/3
    end

    @desc "The bookmarking state of the current user."
    field :is_bookmarked, non_null(:boolean) do
      resolve &Resolvers.is_bookmarked/3
    end

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp) do
      resolve &fetched_at_resolver/2
    end
  end

  @desc "A group membership defines the relationship between a user and group."
  object :group_membership do
    field :group, non_null(:group), resolve: dataloader(Groups)
    field :space_user, non_null(:space_user), resolve: dataloader(Spaces)
    field :state, non_null(:group_membership_state)

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp) do
      resolve &fetched_at_resolver/2
    end
  end

  @desc "A post represents a conversation."
  object :post do
    field :id, non_null(:id)
    field :state, non_null(:post_state)
    field :body, non_null(:string)
    field :space, non_null(:space), resolve: dataloader(Spaces)
    field :author, non_null(:space_user), resolve: dataloader(Spaces)
    field :groups, list_of(:group), resolve: dataloader(Groups)

    field :body_html, non_null(:string) do
      resolve fn post, _, _ ->
        Posts.render_body(post.body)
      end
    end

    field :posted_at, non_null(:time) do
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

    # Viewer-contextual fields
    @desc "The viewer's subscription to the post."
    field :subscription_state, non_null(:post_subscription_state) do
      resolve &Resolvers.subscription_state/3
    end

    @desc "A list of mentions for the current viewer."
    field :mentions, list_of(:mention) do
      resolve &Resolvers.mentions/3
    end

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp) do
      resolve &fetched_at_resolver/2
    end
  end

  @desc "A reply represents a response to a post."
  object :reply do
    field :id, non_null(:id)
    field :post_id, non_null(:id)
    field :body, non_null(:string)
    field :space, non_null(:space), resolve: dataloader(Spaces)
    field :author, non_null(:space_user), resolve: dataloader(Spaces)

    field :body_html, non_null(:string) do
      resolve fn reply, _, _ ->
        Posts.render_body(reply.body)
      end
    end

    field :posted_at, non_null(:time) do
      resolve fn reply, _, _ ->
        {:ok, reply.inserted_at}
      end
    end

    interface :fetch_timeable

    @desc "The timestamp representing when the object was fetched."
    field :fetched_at, non_null(:timestamp) do
      resolve &fetched_at_resolver/2
    end
  end

  @desc "A mention represents a when user has @-mentioned another user."
  object :mention do
    field :mentioner, non_null(:space_user), resolve: dataloader(Spaces)
    field :occurred_at, non_null(:time)
  end

  def fetched_at_resolver(_, _) do
    {:ok, DateTime.utc_now()}
  end
end
