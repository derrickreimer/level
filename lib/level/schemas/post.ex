defmodule Level.Schemas.Post do
  @moduledoc """
  The Post schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Level.Schemas.Group
  alias Level.Schemas.PostFile
  alias Level.Schemas.PostGroup
  alias Level.Schemas.PostLocator
  alias Level.Schemas.PostLog
  alias Level.Schemas.PostReaction
  alias Level.Schemas.PostUser
  alias Level.Schemas.Reply
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.UserMention

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "posts" do
    field :state, :string, read_after_writes: true
    field :body, :string
    field :language, :string
    field :is_urgent, :boolean, read_after_writes: true

    # Overrides
    field :display_name, :string
    field :initials, :string
    field :avatar_color, :string

    belongs_to :space, Space
    belongs_to :space_user, SpaceUser
    belongs_to :space_bot, SpaceBot

    many_to_many :groups, Group, join_through: PostGroup
    has_many :replies, Reply
    has_many :user_mentions, UserMention
    has_many :post_logs, PostLog
    has_many :post_users, PostUser
    has_many :post_files, PostFile
    has_many :files, through: [:post_files, :file]
    has_many :locators, PostLocator
    has_many :post_reactions, PostReaction

    # Used for paginating
    field :last_pinged_at, :naive_datetime, virtual: true
    field :last_activity_at, :naive_datetime, virtual: true

    timestamps()
  end

  @doc false
  def user_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [
      :space_id,
      :space_user_id,
      :body,
      :is_urgent,
      :display_name,
      :initials,
      :avatar_color
    ])
    |> validate_required([:body])
    |> shared_validations()
  end

  @doc false
  def bot_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [
      :space_id,
      :space_bot_id,
      :body,
      :is_urgent,
      :display_name,
      :initials,
      :avatar_color
    ])
    |> validate_required([:body, :display_name])
    |> shared_validations()
  end

  @doc false
  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:body])
    |> validate_required([:body])
  end

  defp shared_validations(changeset) do
    changeset
    |> transform_initials()
    |> validate_length(:display_name, min: 1, max: 20)
    |> validate_length(:initials, min: 1, max: 2)
    |> validate_format(:avatar_color, ~r/^([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/)
  end

  defp transform_initials(%Ecto.Changeset{changes: %{initials: initials}} = changeset)
       when is_binary(initials) do
    put_change(changeset, :initials, String.upcase(initials))
  end

  defp transform_initials(changeset), do: changeset
end
