defmodule Level.DigestsTest do
  use Level.DataCase, async: true

  alias Level.Digests
  alias Level.Posts

  describe "build/2" do
    test "stores digest metadata" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      start_at = one_day_ago()
      end_at = Timex.now()

      {:ok, digest} =
        Digests.build(space_user, %{
          title: "Foo",
          start_at: start_at,
          end_at: end_at
        })

      assert digest.title == "Foo"
      assert digest.start_at == DateTime.to_naive(start_at)
      assert digest.end_at == DateTime.to_naive(end_at)
    end

    test "summarizes inbox activity when there are no unreads" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, digest} = Digests.build(space_user, daily_opts())

      [inbox_section | _] = digest.sections
      assert inbox_section.summary =~ ~r/You have 0 unread posts in your inbox/
    end

    test "summarizes inbox activity when there are unread posts" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      Posts.mark_as_unread(space_user, [post])

      {:ok, digest} = Digests.build(space_user, daily_opts())

      [inbox_section | _] = digest.sections
      assert inbox_section.summary =~ ~r/You have 1 unread post in your inbox/
    end
  end

  defp one_day_ago do
    now = Timex.now()
    Timex.shift(now, hours: -24)
  end

  defp daily_opts do
    %{
      title: "Your Daily Digest",
      start_at: one_day_ago(),
      end_at: Timex.now()
    }
  end
end
