defmodule Bridge.Router do
  use Bridge.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Bridge do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    resources "/pods", PodController, only: [:new, :create]
    resources "/threads", ThreadController
  end

  # Other scopes may use custom stacks.
  # scope "/api", Bridge do
  #   pipe_through :api
  # end
end
