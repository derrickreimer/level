defmodule LevelWeb.PostbotView do
  @moduledoc false

  use LevelWeb, :view

  def render("success.json", %{post: post}) do
    %{success: true, post_id: post.id}
  end

  def render("validation_errors.json", %{changeset: changeset}) do
    changeset
    |> json_validation_errors()
    |> Map.put(:success, false)
    |> Map.put(:reason, "validation_errors")
  end

  def render("error.json", %{reason: reason}) do
    %{success: false, reason: reason}
  end
end
