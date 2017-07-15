defmodule Bridge.Invitation do
  @moduledoc """
  An Invitation is the means by which users are invited to join a Team.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "invitations" do
    field :state, :integer
    field :role, :integer
    field :email, :string
    field :token, :string

    belongs_to :team, Bridge.Team
    belongs_to :invitor, Bridge.User
    belongs_to :acceptor, Bridge.User

    timestamps()
  end
end

defimpl Phoenix.Param, for: Bridge.Invitation do
  def to_param(%{token: token}) do
    token
  end
end
