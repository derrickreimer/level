defmodule Bridge.Web.Router do
  use Bridge.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :validate_host
    plug :extract_subdomain
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

  pipeline :graphql do
    # TODO: add authentication
  end

  scope "/graphql" do
    pipe_through :graphql

    forward "/", Absinthe.Plug,
      schema: Bridge.Web.Schema
  end

  scope "/", Bridge.Web, host: "launch." do
    pipe_through :browser # Use the default browser stack

    get "/", TeamSearchController, :new
    post "/", TeamSearchController, :create
    resources "/teams", TeamController, only: [:new, :create]
  end

  scope "/", Bridge.Web do
    pipe_through :browser

    get "/login", SessionController, :new
    post "/login", SessionController, :create
  end

  scope "/", Bridge.Web do
    pipe_through [:browser, :team]

    get "/", ThreadController, :index
  end

  scope "/api", Bridge.Web do
    pipe_through :api

    resources "/teams", API.TeamController, only: [:create]
    post "/signup/errors", API.SignupErrorsController, :index
  end
end
