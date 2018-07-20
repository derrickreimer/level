defmodule Level.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query
  import Level.Gettext

  alias Level.Repo
  alias Level.Users.Reservation
  alias Level.Users.User

  @doc """
  Fetches a user by id.
  """
  @spec get_user_by_id(String.t()) :: {:ok, User.t()} | {:error, String.t()}
  def get_user_by_id(id) do
    case Repo.get(User, id) do
      %User{} = user ->
        {:ok, user}

      _ ->
        {:error, dgettext("errors", "User not found")}
    end
  end

  @doc """
  Generates a changeset for creating a user.
  """
  @spec create_user_changeset(User.t(), map()) :: Ecto.Changeset.t()
  def create_user_changeset(user, params \\ %{}) do
    User.create_changeset(user, params)
  end

  @doc """
  Creates a new user.
  """
  @spec create_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(params) do
    %User{}
    |> create_user_changeset(params)
    |> Repo.insert()
  end

  @doc """
  Creates a reservation.
  """
  @spec create_reservation(map()) :: {:ok, Reservation.t()} | {:error, Ecto.Changeset.t()}
  def create_reservation(params) do
    %Reservation{}
    |> Reservation.create_changeset(params)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  @spec update_user(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(user, params) do
    user
    |> User.update_changeset(params)
    |> Repo.update()
  end

  @doc """
  Count the number of reservations.
  """
  @spec reservation_count() :: Integer.t()
  def reservation_count do
    Repo.one(from(r in Reservation, select: count(r.id)))
  end
end
