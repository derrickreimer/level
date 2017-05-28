defmodule Bridge.PodController do
  use Bridge.Web, :controller
  alias Bridge.Signup

  def new(conn, _params) do
    changeset = Signup.changeset(%Signup{})
    render conn, "new.html", changeset: changeset
  end
end
