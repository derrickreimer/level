defmodule NeuronWeb.API.SignupErrorsController do
  use NeuronWeb, :controller

  alias Neuron.Teams

  def index(conn, %{"signup" => params}) do
    changeset = Teams.registration_changeset(%{}, params)
    render conn, "show.json", %{changeset: changeset}
  end
end
