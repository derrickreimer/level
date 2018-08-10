defmodule Level.Users.Reservation do
  @moduledoc """
  The Reservation schema.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Level.Gettext

  alias Level.Users
  alias Level.Users.User

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "reservations" do
    field :email, :string
    field :handle, :string

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:email, :handle])
    |> validate_required([:email, :handle])
    |> validate_length(:email, min: 5, max: 254)
    |> validate_format(
      :email,
      User.email_format(),
      message: dgettext("errors", "is not valid")
    )
    |> validate_format(
      :handle,
      Users.handle_format(),
      message: dgettext("errors", "must contain letters, numbers, and dashes only")
    )
    |> unique_constraint(
      :email,
      name: :reservations_lower_email_index,
      message: dgettext("errors", "is already registered")
    )
    |> unique_constraint(
      :handle,
      name: :reservations_lower_handle_index,
      message: dgettext("errors", "is already taken")
    )
  end
end
