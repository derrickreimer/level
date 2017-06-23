defmodule Bridge.Web.Router do
  use Bridge.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :team do
    plug :fetch_team, repo: Bridge.Repo
    plug :fetch_current_user, repo: Bridge.Repo
    plug :authenticate_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", Bridge.Web do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    resources "/teams", TeamController, only: [:new, :create]

    get "/:team_id/login", SessionController, :new
    post "/:team_id/login", SessionController, :create
  end

  scope "/:team_id", Bridge.Web do
    pipe_through [:browser, :team]

    get "/", ThreadController, :index
  end

  scope "/api", Bridge.Web do
    pipe_through :api

    resources "/teams", API.TeamController, only: [:create]
  end
end
