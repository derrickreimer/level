defmodule Bridge.ConnCaseHelpers do
  def render_json(view, template, assigns) do
    assigns = Map.new(assigns)

    template
    |> view.render(assigns)
    |> format_json()
  end

  defp format_json(data) do
    data |> Poison.encode! |> Poison.decode!
  end
end
