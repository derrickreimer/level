defmodule Level.MarkdownTest do
  use Level.DataCase, async: true

  alias Level.Markdown

  describe "to_html/1" do
    test "transforms markdown to HTML" do
      {:ok, result, _} = Markdown.to_html("# Title")
      assert result == "<h1>Title</h1>\n"
    end

    test "scrubs script tags" do
      {:ok, result, _} = Markdown.to_html("<h1>Hello <script>World!</script></h1>")
      assert result == "<h1>Hello World!</h1>"
    end

    test "makes all line breaks significant" do
      {:ok, result, _} = Markdown.to_html("Hello\nWorld")
      assert result == "<p>Hello<br />World</p>\n"
    end
  end
end
