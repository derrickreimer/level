defmodule Level.FilesTest do
  use Level.DataCase, async: true

  alias Level.File
  alias Level.Files

  describe "get_files/2" do
    setup do
      create_user_and_space()
    end

    test "includes uploads owned by the user", %{space_user: space_user} do
      {:ok, %File{id: file_id}} = create_file(space_user)
      [%File{id: ^file_id}] = Files.get_files(space_user, [file_id])
    end

    # TODO: this should probably be expanded to include all uploads
    # accessible by the user (e.g. attached to a post that the user can see)
    test "excludes uploads owned by other users", %{space: space, space_user: space_user} do
      {:ok, %{space_user: another_user}} = create_space_member(space)
      {:ok, %File{id: file_id}} = create_file(another_user)
      [] = Files.get_files(space_user, [file_id])
    end
  end
end
