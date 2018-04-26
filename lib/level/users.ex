defmodule Level.Users do
  @moduledoc """
  The Users context.
  """

  import Level.Gettext

  alias Level.Repo
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
end
