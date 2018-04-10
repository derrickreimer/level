defmodule Level.Connections.Users do
  @moduledoc """
  A paginated connection for fetching a space's users.
  """

  import Ecto.Query

  alias Level.Pagination
  alias Level.Pagination.Args
  alias Level.Repo
  alias Level.Spaces.Space
  alias Level.Spaces.User

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            order_by: %{
              field: :last_name,
              direction: :asc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          order_by: %{field: :last_name, direction: :asc | :desc}
        }

  @doc """
  Executes a paginated query for a space's users.
  """
  def get(%Space{id: space_id} = _space, %__MODULE__{} = args, _context) do
    base_query = from u in User, where: u.space_id == ^space_id and u.state == "ACTIVE"
    Pagination.fetch_result(Repo, base_query, Args.build(args))
  end
end
