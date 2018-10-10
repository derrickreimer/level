defmodule Level.UploadsTest do
  use Level.DataCase, async: true

  alias Level.Upload
  alias Level.Uploads

  describe "get_uploads/2" do
    setup do
      create_user_and_space()
    end

    test "includes uploads owned by the user", %{space_user: space_user} do
      {:ok, %Upload{id: upload_id}} = create_upload(space_user)
      [%Upload{id: ^upload_id}] = Uploads.get_uploads(space_user, [upload_id])
    end

    # TODO: this should probably be expanded to include all uploads
    # accessible by the user (e.g. attached to a post that the user can see)
    test "excludes uploads owned by other users", %{space: space, space_user: space_user} do
      {:ok, %{space_user: another_user}} = create_space_member(space)
      {:ok, %Upload{id: upload_id}} = create_upload(another_user)
      [] = Uploads.get_uploads(space_user, [upload_id])
    end
  end
end
