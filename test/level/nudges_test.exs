defmodule Level.NudgesTest do
  use Level.DataCase, async: true

  alias Ecto.Changeset
  alias Level.Digests
  alias Level.Nudges
  alias Level.Posts
  alias Level.Repo
  alias Level.Schemas.DueNudge
  alias Level.Schemas.Nudge
  alias Level.Schemas.PostLog

  # Note on time zones: America/Phoenix (-7:00) does not currently observe
  # daylight saving time, which makes it a good zone to use for testing offset logic.

  describe "due_query/1" do
    setup do
      create_user_and_space(%{time_zone: "America/Phoenix"})
    end

    test "includes nudges that are due within 30 minutes", %{space_user: space_user} do
      # 3:29 Arizona time
      query = Nudges.due_query(~N[2018-11-01 10:29:00])

      # 3:00
      {:ok, nudge} = Nudges.create_nudge(space_user, %{minute: 180})
      assert query_includes?(query, nudge.id)
    end

    test "does not include nudges that were due over 30 minutes ago", %{space_user: space_user} do
      # 3:31 Arizona time
      query = Nudges.due_query(~N[2018-11-01 10:31:00])

      # 3:00
      {:ok, nudge} = Nudges.create_nudge(space_user, %{minute: 180})
      refute query_includes?(query, nudge.id)
    end

    test "does not include nudges are due in the future", %{space_user: space_user} do
      # 2:59 Arizona time
      query = Nudges.due_query(~N[2018-11-01 09:59:00])

      # 3:00
      {:ok, nudge} = Nudges.create_nudge(space_user, %{minute: 180})
      refute query_includes?(query, nudge.id)
    end

    test "does not include nudge that already have a digest", %{space_user: space_user} do
      # 3:01 Arizona time
      query = Nudges.due_query(~N[2018-11-01 10:01:00])

      # 3:00
      {:ok, nudge} = Nudges.create_nudge(space_user, %{minute: 180})

      {:ok, _digest} =
        Digests.build(space_user, %Digests.Options{
          title: "Recent activity",
          key: "nudge:#{nudge.id}:2018-11-01",
          start_at: ~N[2018-11-01 09:01:00],
          end_at: ~N[2018-11-01 10:01:00],
          time_zone: "America/Phoenix",
          sections: []
        })

      refute query_includes?(query, nudge.id)
    end

    test "handles times very close to midnight", %{space_user: space_user} do
      # 23:50 Arizona time
      query = Nudges.due_query(~N[2018-11-02 06:50:00])

      # 00:10
      {:ok, nudge} = Nudges.create_nudge(space_user, %{minute: 10})

      refute query_includes?(query, nudge.id)
    end
  end

  describe "create_nudge/2" do
    test "inserts a nudge given valid params" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      assert {:ok, %Nudge{}} = Nudges.create_nudge(space_user, %{minute: 660})
    end

    test "returns validation errors if minute is bad" do
      {:ok, %{space_user: space_user}} = create_user_and_space()

      assert {:error, %Changeset{errors: [minute: {"is invalid", [validation: :inclusion]}]}} =
               Nudges.create_nudge(space_user, %{minute: 6000})
    end
  end

  describe "list_nudges/1" do
    test "fetches all nudges for a given user" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, nudge} = Nudges.create_nudge(space_user, %{minute: 660})
      [returned_nudge] = Nudges.list_nudges(space_user)
      assert returned_nudge.id == nudge.id
    end
  end

  describe "get_nudge/2" do
    test "looks up a nudge by id" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, nudge} = Nudges.create_nudge(space_user, %{minute: 660})
      {:ok, returned_nudge} = Nudges.get_nudge(space_user, nudge.id)
      assert returned_nudge.id == nudge.id
    end

    test "returns an error if not found" do
      {:ok, %{space_user: space_user}} = create_user_and_space()

      assert {:error, "Nudge not found"} =
               Nudges.get_nudge(space_user, "11111111-1111-1111-1111-111111111111")
    end
  end

  describe "delete_nudge/2" do
    test "deletes the nudge from the database" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, nudge} = Nudges.create_nudge(space_user, %{minute: 660})
      {:ok, deleted_nudge} = Nudges.delete_nudge(nudge)
      assert {:error, _} = Nudges.get_nudge(space_user, deleted_nudge.id)
    end
  end

  describe "filter_sendable/2" do
    test "keeps records where there is at least one unread with activity today" do
      {:ok, %{space_user: space_user}} = create_user_and_space(%{time_zone: "America/Phoenix"})
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      # Clear out all log entries for the post
      Repo.delete_all(PostLog)

      # 3:00 local time
      now = ~N[2018-11-01 10:00:00] |> DateTime.from_naive!("Etc/UTC")
      space_user_id = space_user.id

      # Log some activity
      {:ok, _} = PostLog.post_edited(post, space_user, now)

      # Mark the post as unread
      {:ok, _} = Posts.mark_as_unread(space_user, [post])

      # Construct due nudge
      due_nudge = %DueNudge{
        id: space_user.id,
        space_id: space_user.space_id,
        space_user_id: space_user.id,
        digest_key: "nudge",
        minute: 0,
        current_minute: 0,
        time_zone: "America/Phoenix"
      }

      assert [%DueNudge{id: ^space_user_id}] = Nudges.filter_sendable([due_nudge], now)
    end

    test "excludes records where there is not at least one unread with activity today" do
      {:ok, %{space_user: space_user}} = create_user_and_space(%{time_zone: "America/Phoenix"})
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      # Clear out all log entries for the post
      Repo.delete_all(PostLog)

      # 3:00 local time
      now = ~N[2018-11-01 10:00:00] |> DateTime.from_naive!("Etc/UTC")
      space_user_id = space_user.id

      # Log some activity a day ago
      {:ok, _} = PostLog.post_edited(post, space_user, ~N[2018-10-31 10:00:00])

      # Mark the post as unread
      {:ok, _} = Posts.mark_as_unread(space_user, [post])

      # Construct due nudge
      due_nudge = %DueNudge{
        id: space_user.id,
        space_id: space_user.space_id,
        space_user_id: space_user.id,
        digest_key: "nudge",
        minute: 0,
        current_minute: 0,
        time_zone: "America/Phoenix"
      }

      refute [due_nudge]
             |> Nudges.filter_sendable(now)
             |> Enum.any?(fn result -> result.space_user.id == space_user_id end)
    end
  end

  defp query_includes?(query, id) do
    Enum.any?(Repo.all(query), fn result -> result.id == id end)
  end
end
