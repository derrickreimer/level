defmodule Level.Pagination.ValidationsTest do
  use Level.DataCase, async: true

  alias Level.Pagination.Args
  alias Level.Pagination.Validations

  @valid_args %Args{before: nil, after: nil, first: 10, last: nil}

  describe "validate_limit/1" do
    test "requires at least first or last to be set" do
      args = Map.merge(@valid_args, %{first: nil, last: nil})

      assert Validations.validate_limit(args) ==
               {:error, "You must provide either a `first` or `last` value"}
    end

    test "requires that both first and last are not set" do
      args = Map.merge(@valid_args, %{first: 10, last: 10})

      assert Validations.validate_limit(args) ==
               {:error, "You must provide either a `first` or `last` value"}
    end

    test "returns success if valid" do
      assert Validations.validate_limit(@valid_args) == {:ok, @valid_args}
    end
  end
end
