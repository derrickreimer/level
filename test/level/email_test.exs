defmodule Level.EmailTest do
  use Level.DataCase, async: true
  use Bamboo.Test

  alias Level.Digests.Digest
  alias Level.Email

  describe "digest/1" do
    test "has the right subject and recipient" do
      digest = build_digest()
      email = Email.digest(digest)
      assert email.subject == "[CoffeeKit] Your Daily Digest"
      assert email.to == "derrick@level.app"
    end

    test "contains the right header data" do
      digest = build_digest()
      email = Email.digest(digest)

      assert email.html_body =~ ~r/<h1.*>Your Daily Digest<\/h1>/
      assert email.html_body =~ "Friday, November 2, 2018"
      assert email.html_body =~ "@ 10:00 am"
    end
  end

  defp build_digest do
    %Digest{
      id: "11111111-1111-1111-1111-111111111111",
      space_id: "11111111-1111-1111-1111-111111111111",
      space_name: "CoffeeKit",
      space_slug: "coffeekit",
      title: "Your Daily Digest",
      subject: "[CoffeeKit] Your Daily Digest",
      to_email: "derrick@level.app",
      sections: [],
      start_at: ~N[2018-11-01 10:00:00],
      end_at: ~N[2018-11-02 10:00:00],
      time_zone: "Etc/UTC"
    }
  end
end
