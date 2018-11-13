defmodule Level.DailyDigestTest do
  use Level.DataCase, async: true

  alias Level.DailyDigest
  alias Level.DailyDigest.Result
  alias Level.Digests
  alias Level.Repo
  alias Level.Schemas.SpaceUser

  describe "due_query/1" do
    setup do
      {:ok, %{current_hour: get_current_hour()}}
    end

    # TODO: this test breaks between 00:00 and 1:00 UTC
    test "includes users who have not yet received the digest and are due", %{
      current_hour: current_hour
    } do
      {:ok, %{space_user: %SpaceUser{id: space_user_id}}} =
        create_user_and_space(%{time_zone: "Etc/UTC"})

      query = DailyDigest.due_query(current_hour - 1)
      assert [%Result{id: ^space_user_id}] = Repo.all(query)
    end

    # TODO: this test breaks between 23:00 and 00:00 UTC
    test "does not include users that are not yet due", %{current_hour: current_hour} do
      {:ok, %{space_user: _}} = create_user_and_space(%{time_zone: "Etc/UTC"})

      query = DailyDigest.due_query(current_hour + 1)
      assert [] = Repo.all(query)
    end

    # TODO: this test breaks between 00:00 and 1:00 UTC
    test "does not include users who have yet received the digest already", %{
      current_hour: current_hour
    } do
      {:ok, %{space_user: %SpaceUser{id: space_user_id} = space_user}} =
        create_user_and_space(%{time_zone: "Etc/UTC"})

      # Obtain the proper digest key
      query = DailyDigest.due_query(current_hour)
      [%Result{id: ^space_user_id, digest_key: digest_key}] = Repo.all(query)

      # Build the digest
      {:ok, opts} = DailyDigest.build_options(digest_key, DateTime.utc_now())
      {:ok, _} = Digests.build(space_user, opts)

      # Verify that the user no longer appears in the results
      query = DailyDigest.due_query(current_hour)
      assert [] = Repo.all(query)
    end
  end

  def get_current_hour do
    DateTime.utc_now().hour
  end
end
