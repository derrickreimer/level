defmodule Level.Markdown.Scrubber do
  @moduledoc """
  Allows basic HTML tags to support user input for writing relatively
  plain text with Markdown (GitHub flavoured Markdown supported).
  Technically this is a more relaxed version of the BasicHTML scrubber.
  Does not allow any mailto-links, styling, HTML5 tags, video embeds etc.

  Based on [HtmlSanitizeEx.Scrubber.MarkdownHTML](https://github.com/rrrene/html_sanitize_ex/blob/91ca3dd14c5ce5d6eb41fca47afea4a47ddce1c7/lib/html_sanitize_ex/scrubber/markdown_html.ex).
  """

  require HtmlSanitizeEx.Scrubber.Meta
  alias HtmlSanitizeEx.Scrubber.Meta

  @valid_schemes ["http", "https", "mailto"]

  # Removes any CDATA tags before the traverser/scrubber runs.
  Meta.remove_cdata_sections_before_scrub()

  Meta.strip_comments()

  Meta.allow_tag_with_uri_attributes("a", ["href"], @valid_schemes)
  Meta.allow_tag_with_these_attributes("a", ["name", "title"])

  Meta.allow_tag_with_this_attribute_values("a", "target", ["_blank"])

  Meta.allow_tag_with_this_attribute_values("a", "rel", [
    "noopener",
    "noreferrer"
  ])

  Meta.allow_tag_with_these_attributes("b", [])
  Meta.allow_tag_with_these_attributes("blockquote", [])
  Meta.allow_tag_with_these_attributes("br", [])
  Meta.allow_tag_with_these_attributes("code", ["class"])
  Meta.allow_tag_with_these_attributes("del", [])
  Meta.allow_tag_with_these_attributes("em", [])
  Meta.allow_tag_with_these_attributes("h1", [])
  Meta.allow_tag_with_these_attributes("h2", [])
  Meta.allow_tag_with_these_attributes("h3", [])
  Meta.allow_tag_with_these_attributes("h4", [])
  Meta.allow_tag_with_these_attributes("h5", [])
  Meta.allow_tag_with_these_attributes("hr", [])
  Meta.allow_tag_with_these_attributes("i", [])

  Meta.allow_tag_with_uri_attributes("img", ["src"], @valid_schemes)

  Meta.allow_tag_with_these_attributes("img", [
    "width",
    "height",
    "title",
    "alt"
  ])

  Meta.allow_tag_with_these_attributes("li", [])
  Meta.allow_tag_with_these_attributes("ol", [])
  Meta.allow_tag_with_these_attributes("p", [])
  Meta.allow_tag_with_these_attributes("pre", [])
  Meta.allow_tag_with_these_attributes("span", [])
  Meta.allow_tag_with_these_attributes("strong", [])
  Meta.allow_tag_with_these_attributes("table", [])
  Meta.allow_tag_with_these_attributes("tbody", [])
  Meta.allow_tag_with_these_attributes("td", [])
  Meta.allow_tag_with_these_attributes("th", [])
  Meta.allow_tag_with_these_attributes("thead", [])
  Meta.allow_tag_with_these_attributes("tr", [])
  Meta.allow_tag_with_these_attributes("u", [])
  Meta.allow_tag_with_these_attributes("ul", [])

  # Customizations

  # The <mark> tag is used to highlight search results.
  Meta.allow_tag_with_these_attributes("mark", [])

  Meta.strip_everything_not_covered()
end
