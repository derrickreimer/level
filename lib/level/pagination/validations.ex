defmodule Level.Pagination.Validations do
  @moduledoc """
  Validation helpers for pagination.
  """

  import Level.Gettext

  @doc """
  Validates the cursor arguments for pagination.

  ## Examples

      validate_cursor(%{before: "aaa", after: "aaa"})
      => {:error, "You must provide either a `before` or `after` value"}

      validate_cursor(%{before: "aaa", after: nil})
      => {:ok, %{before: "aaa", after: nil}}

  """
  def validate_cursor(%{before: before_cursor, after: after_cursor})
      when is_binary(before_cursor) and is_binary(after_cursor) do
    {:error, dgettext("errors", "You cannot provide both a `before` and `after` value")}
  end

  def validate_cursor(args), do: {:ok, args}

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
  def validate_limit(%{first: nil, last: nil}) do
    {:error, dgettext("errors", "You must provide either a `first` or `last` value")}
  end

  def validate_limit(%{first: first, last: last})
      when is_integer(first) and is_integer(last) do
    {:error, dgettext("errors", "You must provide either a `first` or `last` value")}
  end

  def validate_limit(args), do: {:ok, args}
end
