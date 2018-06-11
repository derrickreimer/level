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
    {status, html, errors} = Earmark.as_html(input, %Options{gfm: true, breaks: true})
    sanitized_html = HtmlSanitizeEx.markdown_html(html)
    {status, sanitized_html, errors}
  end
end
