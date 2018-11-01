defmodule Level.Markdown do
  @moduledoc """
  Functions for generating safe HTML from markdown input.
  """

  alias Earmark.Options

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
    tree =
      html
      |> Floki.parse()
      |> Floki.map(&autolink_node/1)

    {status, Floki.raw_html(tree), errors}
  end

  defp autolink_node(value) do
    value
  end
end
