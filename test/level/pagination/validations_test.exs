defmodule Level.Pagination.ValidationsTest do
  use Level.DataCase, async: true

  alias Level.Pagination.Validations

  @valid_args %{before: nil, after: nil, first: 10, last: nil}

  describe "validate_cursor/1" do
    test "requires that both before and after are not set" do
      args = Map.merge(@valid_args, %{before: "123", after: "456"})

      assert Validations.validate_cursor(args) ==
               {:error, "You cannot provide both a `before` and `after` value"}
    end

    test "returns success if either before or after is set" do
      args = Map.merge(@valid_args, %{before: "aaa", after: nil})
      assert Validations.validate_cursor(args) == {:ok, args}

      args = Map.merge(@valid_args, %{before: nil, after: "aaa"})
      assert Validations.validate_cursor(args) == {:ok, args}
    end

    test "returns success if neither before nor after are set" do
      args = Map.merge(@valid_args, %{before: nil, after: nil})
      assert Validations.validate_cursor(args) == {:ok, args}
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
