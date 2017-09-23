defmodule SprinkleWeb.UrlHelpersTest do
  use Sprinkle.DataCase, async: true

  alias SprinkleWeb.UrlHelpers

  describe "build_url_with_subdomain/3" do
    test "prepends the given subdomain to the default host" do
      config = [host: "example.com"]
      assert UrlHelpers.build_url_with_subdomain("foo", "/", config) =~ "foo.example.com/"
    end

    test "defaults to http scheme" do
      config = [host: "example.com"]
      assert UrlHelpers.build_url_with_subdomain("foo", "/", config) =~ "http://"
    end

    test "excludes port if 80" do
      config = [host: "example.com", port: 80]
      assert UrlHelpers.build_url_with_subdomain("foo", "/", config) =~ "http://foo.example.com/"
    end

    test "excludes port if 443" do
      config = [host: "example.com", port: 443]
      assert UrlHelpers.build_url_with_subdomain("foo", "/", config) =~ "http://foo.example.com/"
    end

    test "injects the port if non-standard" do
      config = [host: "example.com", port: 444]
      assert UrlHelpers.build_url_with_subdomain("foo", "/", config) =~ "foo.example.com:444/"
    end

    test "excludes a subdomain if nil" do
      config = [host: "example.com", port: 444]
      assert UrlHelpers.build_url_with_subdomain(nil, "/", config) =~ "http://example.com:444/"
    end

    test "allows https scheme" do
      config = [host: "example.com", scheme: "https"]
      assert UrlHelpers.build_url_with_subdomain("foo", "/", config) =~ "https://"
    end
  end
end
