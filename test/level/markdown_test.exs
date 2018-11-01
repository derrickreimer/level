defmodule Level.MarkdownTest do
  use Level.DataCase, async: true

  alias Level.Markdown

  describe "to_html/1" do
    test "transforms markdown to HTML" do
      {:ok, result, _} = Markdown.to_html("# Title")
      assert result == "<h1>Title</h1>"
    end

    test "scrubs script tags" do
      {:ok, result, _} = Markdown.to_html("<h1>Hello <script>World!</script></h1>")
      assert result == "<h1>Hello World!</h1>"
    end

    test "makes all line breaks significant" do
      {:ok, result, _} = Markdown.to_html("Hello\nWorld")
      assert result == "<p>Hello<br/>World</p>"
    end

    test "auto-hyperlinks urls" do
      {:ok, result, _} = Markdown.to_html("Look at https://level.app")
      assert result == ~s(<p>Look at <a href="https://level.app">https://level.app</a></p>)
    end

    test "does not convert urls to links inside code blocks" do
      markdown = """
      ```
      https://level.app
      ```
      """

      {:ok, result, _} = Markdown.to_html(markdown)

      assert result == ~s(<pre><code class="">https://level.app</code></pre>)
    end

    test "does not convert urls to links inside other links" do
      markdown = """
      [https://level.app](https://google.com)
      """

      {:ok, result, _} = Markdown.to_html(markdown)

      assert result == ~s(<p><a href="https://google.com">https://level.app</a></p>)
    end

    test "highlights mentions" do
      {:ok, result, _} = Markdown.to_html("Hey @derrick")
      assert result == ~s(<p>Hey <strong class="user-mention">@derrick</strong></p>)
    end
  end
end
