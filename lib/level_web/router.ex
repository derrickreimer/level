defmodule LevelWeb.Router do
  @moduledoc false

  use LevelWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :browser_api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :put_secure_browser_headers
  end

  pipeline :graphql do
    plug :authenticate_with_token
  end

  # GraphQL API
  scope "/" do
    pipe_through :graphql
    forward "/graphql", Absinthe.Plug, schema: LevelWeb.Schema
  end

  # Graphiql Explorer
  forward "/graphiql", Absinthe.Plug.GraphiQL,
    schema: LevelWeb.Schema,
    socket: LevelWeb.UserSocket,
    default_headers: {__MODULE__, :graphiql_headers},
    default_url: "/graphql"

  # Unauthenticated routes
  scope "/", LevelWeb do
    pipe_through :browser

    get "/login", SessionController, :new
    post "/login", SessionController, :create

    resources "/invitations", InvitationController
    post "/invitations/:id/accept", AcceptInvitationController, :create
  end

  # Authenticated routes
  scope "/", LevelWeb do
    pipe_through [:browser, :fetch_current_user_by_session, :authenticate_user]

    resources "/spaces", SpaceController
    get "/", CockpitController, :index
  end

  # RESTful API endpoints authenticated via browser cookies
  scope "/api", LevelWeb.API do
    pipe_through :browser_api
    resources "/tokens", UserTokenController, only: [:create]
  end

  scope "/api", LevelWeb.API do
    pipe_through [:browser_api, :protect_from_forgery]

    resources "/spaces", SpaceController, only: [:create]
    post "/signup/errors", SignupErrorsController, :index

    resources "/tokens", UserTokenController, only: [:create]
  end

  # Preview sent emails in development mode
  if Mix.env() == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end

  # TODO: Set no headers if there is no current user
  def graphiql_headers(conn) do
    token = LevelWeb.Auth.generate_signed_jwt(conn.assigns.current_user)
    %{"Authorization" => "Bearer #{token}"}
  end
end
