defmodule LevelWeb.PostbotController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Postbot
  alias Level.Posts
  alias Level.Schemas.SpaceBot
  alias Level.Spaces

  def create(conn, %{"space_slug" => space_slug, "key" => key} = params) do
    space_slug
    |> Spaces.get_space_by_slug()
    |> check_key(key)
    |> get_bot()
    |> create_post(params)
    |> build_response(conn)
  end

  # Internal functions

  defp check_key({:ok, space}, key) do
    if space.postbot_key == key do
      {:ok, space}
    else
      {:error, "url_not_recognized"}
    end
  end

  defp check_key({:error, _}, _) do
    {:error, "url_not_recognized"}
  end

  defp get_bot({:ok, space}) do
    case Postbot.get_space_bot(space) do
      %SpaceBot{} = bot ->
        {:ok, %{space: space, space_bot: bot}}

      _ ->
        {:error, "url_not_recognized"}
    end
  end

  defp get_bot(err), do: err

  defp create_post({:ok, %{space_bot: space_bot}}, params) do
    Posts.create_post(space_bot, %{
      body: params["body"],
      display_name: params["display_name"],
      initials: params["initials"],
      avatar_color: params["avatar_color"]
    })
  end

  defp create_post(err, _), do: err

  defp build_response({:ok, %{post: post}}, conn) do
    conn
    |> put_status(200)
    |> render("success.json", %{post: post})
  end

  defp build_response({:error, :post, %Ecto.Changeset{} = changeset, _}, conn) do
    conn
    |> put_status(422)
    |> render("validation_errors.json", %{changeset: changeset})
  end

  defp build_response({:error, %Ecto.Changeset{} = changeset}, conn) do
    conn
    |> put_status(422)
    |> render("validation_errors.json", %{changeset: changeset})
  end

  defp build_response({:error, reason}, conn) do
    conn
    |> put_status(422)
    |> render("error.json", %{reason: reason})
  end
end
