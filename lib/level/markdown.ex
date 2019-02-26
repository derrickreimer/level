defmodule Level.Markdown do
  @moduledoc """
  Functions for generating safe HTML from markdown input.
  """

  alias Earmark.Options
  alias Level.Mentions
  alias Level.TaggedGroups
  alias LevelWeb.Router

  @url_regex ~r/\bhttps?:\/\/
    [a-zA-Z0-9\-\._~:\/\?#\[\]@!$&'\(\)\*\+,;=%]+
    [a-zA-Z0-9\-_~:\/\?#\[\]@!$&\*\+;=%]/ix

  @immutable_tags ["a", "code"]

  @doc """
  Convert a string of Markdown to HTML.
  """
  @spec to_html(String.t(), map()) :: {:ok, String.t(), [any()]} | {:error, String.t(), [any()]}
  def to_html(input, context \\ %{}) do
    input
    |> markdownify()
    |> sanitize()
    |> apply_text_mutations(context)
  end

  defp markdownify(input) do
    Earmark.as_html(input, %Options{gfm: true, breaks: true})
  end

  defp sanitize({status, html, errors}) do
    {status, HtmlSanitizeEx.markdown_html(html), errors}
  end

  defp apply_text_mutations({status, html, errors}, context) do
    new_html =
      html
      |> Floki.parse()
      |> map_mutable_text(fn text -> mutate_text(text, context) end)
      |> Floki.raw_html(encode: true)

    {status, new_html, errors}
  end

  def map_mutable_text(nodes, mapper) when is_list(nodes) do
    Enum.map(nodes, fn node -> map_mutable_text(node, mapper) end)
  end

  def map_mutable_text({_, _, []} = node, _), do: node

  def map_mutable_text({tag_name, attrs, children} = node, mapper) do
    if Enum.member?(@immutable_tags, tag_name) do
      node
    else
      {tag_name, attrs, map_mutable_text(children, mapper)}
    end
  end

  def map_mutable_text(node, mapper) when is_binary(node), do: mapper.(node)

  defp mutate_text(text, context) do
    text
    |> autolink()
    |> highlight_hashtags(context)
    |> highlight_mentions(context)
    |> String.replace(~r/>[ \n\r]+</, ">&#32;<")
    |> Floki.parse()
    |> after_mutate_text()
  end

  defp after_mutate_text(nodes) when is_list(nodes), do: {"span", [], nodes}
  defp after_mutate_text(node), do: node

  defp autolink(text) do
    Regex.replace(@url_regex, text, &build_link/1)
  end

  defp build_link(url), do: ~s(<a href="#{url}">#{url}</a>)

  defp highlight_mentions(text, %{space: space, absolute: true} = context) do
    Regex.replace(Mentions.mention_pattern(), text, fn match, handle ->
      href = absolute_user_url(space, handle)
      classes = mention_classes(handle, context)

      String.replace(
        match,
        "@#{handle}",
        ~s(<a href="#{href}" class="#{classes}">@#{handle}</a>)
      )
    end)
  end

  defp highlight_mentions(text, %{space: space} = context) do
    Regex.replace(Mentions.mention_pattern(), text, fn match, handle ->
      href = "/#{space.slug}/users/#{handle}"
      classes = mention_classes(handle, context)

      String.replace(
        match,
        "@#{handle}",
        ~s(<a href="#{href}" class="#{classes}">@#{handle}</a>)
      )
    end)
  end

  defp highlight_mentions(text, context) do
    Regex.replace(Mentions.mention_pattern(), text, fn match, handle ->
      String.replace(
        match,
        "@#{handle}",
        ~s(<span class="#{mention_classes(handle, context)}">@#{handle}</span>)
      )
    end)
  end

  def mention_classes(handle, %{user: current_user}) do
    if current_user.handle == handle do
      "user-mention user-mention-current"
    else
      "user-mention"
    end
  end

  def mention_classes(_, _) do
    "user-mention"
  end

  defp highlight_hashtags(text, %{space: space, absolute: true}) do
    Regex.replace(TaggedGroups.hashtag_pattern(), text, fn match, name ->
      href = absolute_channel_url(space, name)

      String.replace(
        match,
        "##{name}",
        ~s(<a href="#{href}" class="tagged-group">##{name}</a>)
      )
    end)
  end

  defp highlight_hashtags(text, %{space: space}) do
    Regex.replace(TaggedGroups.hashtag_pattern(), text, fn match, name ->
      href = "/#{space.slug}/channels/#{name}"

      String.replace(
        match,
        "##{name}",
        ~s(<a href="#{href}" class="tagged-group">##{name}</a>)
      )
    end)
  end

  defp highlight_hashtags(text, _) do
    Regex.replace(TaggedGroups.hashtag_pattern(), text, fn match, name ->
      String.replace(
        match,
        "##{name}",
        ~s(<span class="tagged-group">##{name}</span>)
      )
    end)
  end

  defp absolute_user_url(space, name) do
    Router.Helpers.main_url(LevelWeb.Endpoint, :index, [space.slug, "users", name])
  end

  defp absolute_channel_url(space, name) do
    Router.Helpers.main_url(LevelWeb.Endpoint, :index, [space.slug, "channels", name])
  end
end
