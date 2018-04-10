defmodule Level.Connections.Invitations do
  @moduledoc """
  A paginated connection for fetching a space's pending invitations.
  """

  import Ecto.Query
  import Level.Pagination.Validations

  alias Level.Pagination
  alias Level.Repo
  alias Level.Spaces.Invitation
  alias Level.Spaces.Space

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            order_by: %{
              field: :email,
              direction: :asc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          order_by: %{field: :email, direction: :asc | :desc}
        }

  @doc """
  Executes a paginated query for a space's pending invitations.
  """
  def get(%Space{id: space_id} = _space, %__MODULE__{} = args, _context) do
    case validate_args(args) do
      {:ok, args} ->
        base_query = from i in Invitation, where: i.space_id == ^space_id and i.state == "PENDING"
        Pagination.fetch_result(Repo, base_query, args)

      err ->
        err
    end
  end

  defp validate_args(args) do
    with {:ok, args} <- validate_cursor(args),
         {:ok, args} <- validate_limit(args) do
      {:ok, args}
    else
      err -> err
    end
  end
end
