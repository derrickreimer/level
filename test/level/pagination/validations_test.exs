defmodule Level.Pagination.ValidationsTest do
  use Level.DataCase, async: true

  alias Level.Pagination.Validations

  @valid_args %{before: "123", after: nil, first: 10, last: nil}

  describe "validate_cursor/1" do
    test "requires at least before or after to be set" do
      args = Map.merge(@valid_args, %{before: nil, after: nil})

      assert Validations.validate_cursor(args) ==
               {:error, "You must provide either a `before` or `after` value"}
    end

    test "requires that both before and after are not set" do
      args = Map.merge(@valid_args, %{before: "123", after: "456"})

      assert Validations.validate_cursor(args) ==
               {:error, "You must provide either a `before` or `after` value"}
    end

    test "returns success if valid" do
      assert Validations.validate_cursor(@valid_args) == {:ok, @valid_args}
    end
  end

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
