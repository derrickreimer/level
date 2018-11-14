defmodule Level.DigestsTest do
  use Level.DataCase, async: true
  use Bamboo.Test

  alias Level.Digests
  alias Level.Digests.Digest
  alias Level.Digests.Options
  alias Level.Email
  alias Level.Posts

  describe "get_digest/2" do
    test "fetches by space id and digest id" do
      {:ok, %{space: space, space_user: space_user}} = create_user_and_space()
      {:ok, %Digest{id: digest_id}} = Digests.build(space_user, daily_opts())

      assert {:ok, %Digest{id: ^digest_id}} = Digests.get_digest(space.id, digest_id)
    end

    test "returns an error if space and digest pair do not match" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %Digest{id: digest_id}} = Digests.build(space_user, daily_opts())

      dummy_id = "11111111-1111-1111-1111-111111111111"
      assert {:error, _} = Digests.get_digest(dummy_id, digest_id)
    end
  end

  describe "build/2" do
    test "stores digest metadata" do
      {:ok, %{space_user: space_user}} = create_user_and_space(%{}, %{name: "Myspace"})

      start_at = one_day_ago()
      end_at = Timex.now()

      {:ok, digest} =
        Digests.build(space_user, %Options{
          title: "Tom's Digest",
          key: "daily",
          start_at: start_at,
          end_at: end_at
        })

      assert digest.title == "Tom's Digest"
      assert digest.subject == "[Myspace] Tom's Digest"
      assert digest.start_at == DateTime.to_naive(start_at)
      assert digest.end_at == DateTime.to_naive(end_at)
    end

    test "summarizes inbox activity when there are no unreads" do
      {:ok, %{space_user: space_user}} = create_user_and_space()

      {:ok, digest} = Digests.build(space_user, daily_opts())

      [inbox_section | _] = digest.sections

      assert inbox_section.summary =~ ~r/Congratulations! You've achieved Inbox Zero./
    end

    test "summarizes inbox activity when there are unread posts" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      post = create_unread_post(space_user, group)

      {:ok, digest} = Digests.build(space_user, daily_opts())

      [inbox_section | _] = digest.sections
      assert inbox_section.summary =~ ~r/You have 1 unread post in your inbox/

      assert Enum.any?(inbox_section.posts, fn section_post ->
               section_post.id == post.id
             end)
    end

    test "summarizes inbox activity when there are unread and read posts" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      create_unread_post(space_user, group)
      create_read_post(space_user, group)

      {:ok, digest} = Digests.build(space_user, daily_opts())

      [inbox_section | _] = digest.sections

      assert inbox_section.summary =~
               ~r/You have 1 unread post and 1 post you have already seen in your inbox/
    end

    test "summarizes inbox activity when there are only read posts" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      create_read_post(space_user, group)

      {:ok, digest} = Digests.build(space_user, daily_opts())

      [inbox_section | _] = digest.sections
      assert inbox_section.summary =~ ~r/You have 1 post in your inbox/
    end
  end

  describe "send_email/1" do
    test "delivers the digest" do
      digest = %Digest{
        id: "11111111-1111-1111-1111-111111111111",
        space_id: "11111111-1111-1111-1111-111111111111",
        title: "Your Daily Digest",
        subject: "[Level] Your Daily Digest",
        to_email: "derrick@level.app",
        sections: [],
        start_at: Timex.to_datetime({{2018, 11, 1}, {10, 0, 0}}, "America/Chicago"),
        end_at: Timex.to_datetime({{2018, 11, 2}, {10, 0, 0}}, "America/Chicago")
      }

      Digests.send_email(digest)
      assert_delivered_email(Email.digest(digest))
    end
  end

  defp one_day_ago do
    now = Timex.now()
    Timex.shift(now, hours: -24)
  end

  defp daily_opts do
    %Options{
      title: "Your Daily Digest",
      key: "daily",
      start_at: one_day_ago(),
      end_at: Timex.now()
    }
  end

  defp create_unread_post(space_user, group) do
    {:ok, %{post: post}} = create_post(space_user, group)
    Posts.mark_as_unread(space_user, [post])
    post
  end

  defp create_read_post(space_user, group) do
    {:ok, %{post: post}} = create_post(space_user, group)
    Posts.mark_as_read(space_user, [post])
    post
  end
end
