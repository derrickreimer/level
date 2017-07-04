defmodule Bridge.Web.Schema.Types do
  use Absinthe.Schema.Notation

  scalar :time do
    description "ISO-8601 time"
    parse &Timex.parse(&1.value, "{ISO:Extended:Z}")
    serialize &Timex.format!(&1, "{ISO:Extended:Z}")
  end

  object :user do
    field :id, :id
    field :email, non_null(:string)
    field :username, non_null(:string)
    field :first_name, :string
    field :last_name, :string
    field :time_zone, :string
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)
  end

  object :team do
    field :id, :id
    field :name, non_null(:string)
    field :slug, non_null(:string)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)
  end
end
