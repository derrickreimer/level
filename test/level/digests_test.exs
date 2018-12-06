defmodule Level.DigestsTest do
  use Level.DataCase, async: true
  use Bamboo.Test

  alias Level.Digests
  alias Level.Digests.Digest
  alias Level.Digests.Options
  alias Level.Email

  describe "get_digest/2" do
    test "fetches by space id and digest id" do
      {:ok, %{space: space, space_user: space_user}} = create_user_and_space()
      {:ok, %Digest{id: digest_id}} = Digests.build(space_user, opts())

      assert {:ok, %Digest{id: ^digest_id}} = Digests.get_digest(space.id, digest_id)
    end

    test "returns an error if space and digest pair do not match" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %Digest{id: digest_id}} = Digests.build(space_user, opts())

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
          end_at: end_at,
          time_zone: "Etc/UTC"
        })

      assert digest.title == "Tom's Digest"
      assert digest.subject == "[Myspace] Tom's Digest"
      assert digest.start_at == DateTime.to_naive(start_at)
      assert digest.end_at == DateTime.to_naive(end_at)
    end
  end

  describe "send_email/1" do
    test "delivers the digest" do
      digest = %Digest{
        id: "11111111-1111-1111-1111-111111111111",
        space_id: "11111111-1111-1111-1111-111111111111",
        space_name: "Level",
        space_slug: "level",
        title: "Your Daily Digest",
        subject: "[Level] Your Daily Digest",
        to_email: "derrick@level.app",
        sections: [],
        start_at: ~N[2018-11-01 10:00:00],
        end_at: ~N[2018-11-02 10:00:00],
        time_zone: "Etc/UTC"
      }

      Digests.send_email(digest)
      assert_delivered_email(Email.digest(digest))
    end
  end

  defp one_day_ago do
    now = Timex.now()
    Timex.shift(now, hours: -24)
  end

  defp opts do
    %Options{
      title: "Your Daily Digest",
      key: "daily",
      start_at: one_day_ago(),
      end_at: Timex.now(),
      time_zone: "Etc/UTC"
    }
  end
end
