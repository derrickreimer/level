defmodule Level.Markdown do
  @moduledoc """
  Functions for generating safe HTML from markdown input.
  """

  alias Earmark.Options

  @url_regex ~r/\bhttps?:\/\/
    [a-zA-Z0-9\-\._~:\/\?#\[\]@!$&'\(\)\*\+,;=%]+
    [a-zA-Z0-9\-_~:\/\?#\[\]@!$&\*\+;=%]/ix

  @unlinkable_tag_names ["code"]

  @doc """
  Convert a string of Markdown to HTML.
  """
  @spec to_html(String.t()) :: {:ok, String.t(), [any()]} | {:error, String.t(), [any()]}
  def to_html(input) do
    input
    |> markdownify()
    |> sanitize()
    |> autolink()
  end

  defp markdownify(input) do
    Earmark.as_html(input, %Options{gfm: true, breaks: true})
  end

  defp sanitize({status, html, errors}) do
    {status, HtmlSanitizeEx.markdown_html(html), errors}
  end

  defp autolink({status, html, errors}) do
    autolinked_html =
      html
      |> Floki.parse()
      |> map_linkable_text(&replace_urls/1)
      |> Floki.raw_html(encode: false)

    {status, autolinked_html, errors}
  end

  def map_linkable_text(nodes, mapper) when is_list(nodes) do
    Enum.map(nodes, fn node -> map_linkable_text(node, mapper) end)
  end

  def map_linkable_text({_, _, []} = node, _), do: node

  def map_linkable_text({tag_name, attrs, children} = node, mapper) do
    if Enum.member?(@unlinkable_tag_names, tag_name) do
      node
    else
      {tag_name, attrs, map_linkable_text(children, mapper)}
    end
  end

  def map_linkable_text(node, mapper) when is_binary(node), do: mapper.(node)

  defp replace_urls(text) do
    Regex.replace(@url_regex, text, &build_link/1)
  end

  defp build_link(url), do: ~s(<a href="#{url}">#{url}</a>)
end
