defmodule LevelWeb.OpenInvitationController do
  @moduledoc false

  use LevelWeb, :controller

  def show(conn, %{"id" => invitation_token}) do
    render conn, "show.html"
  end
end
