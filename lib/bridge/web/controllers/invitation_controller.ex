defmodule Bridge.Web.InvitationController do
  use Bridge.Web, :controller
  alias Bridge.Invitation

  def show(conn, %{"id" => id}) do
    # TODO: look up unexpired invitation by token
    render conn, "show.html"
  end
end
