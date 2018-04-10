defmodule Level.Pagination.Validations do
  @moduledoc false

  import Level.Gettext

  alias Level.Pagination.Args

  @doc """
  Validates the limit arguments for pagination.

  ## Examples

      validate_limit(%{first: nil, last: nil})
      => {:error, "You must provide either a `first` or `last` value}

      validate_limit(%{first: 10, last: 10})
      => {:error, "You must provide either a `first` or `last` value"}

      validate_limit(%{first: 10, last: nil})
      => {:ok, %{first: 10, last: nil}}

  """
  def validate_limit(%Args{first: nil, last: nil}) do
    {:error, dgettext("errors", "You must provide either a `first` or `last` value")}
  end

  def validate_limit(%Args{first: first, last: last})
      when is_integer(first) and is_integer(last) do
    {:error, dgettext("errors", "You must provide either a `first` or `last` value")}
  end

  def validate_limit(args), do: {:ok, args}
end
