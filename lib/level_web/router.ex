defmodule LevelWeb.Router do
  @moduledoc false

  use LevelWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :validate_host
    plug :extract_subdomain
  end

  pipeline :space do
    plug :fetch_space
    plug :fetch_current_user_by_session
    plug :authenticate_user
  end

  pipeline :browser_api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :put_secure_browser_headers
    plug :validate_host
    plug :extract_subdomain
  end

  pipeline :csrf do
    plug :protect_from_forgery
  end

  pipeline :graphql do
    plug :validate_host
    plug :extract_subdomain
    plug :fetch_space
    plug :authenticate_with_token
  end

  # GraphQL API
  scope "/" do
    pipe_through :graphql
    forward "/graphql", Absinthe.Plug, schema: LevelWeb.Schema
  end

  # Launcher-scoped routes
  scope "/", LevelWeb, host: "launch." do
    # Use the default browser stack
    pipe_through :browser

    get "/", SpaceController, :index
    get "/spaces/new", SpaceController, :new
    get "/spaces/search", SpaceSearchController, :new
    post "/spaces/search", SpaceSearchController, :create
  end

  # Space-scoped routes not requiring authentication
  scope "/", LevelWeb do
    pipe_through :browser

    # Authentication
    get "/login", SessionController, :new
    post "/login", SessionController, :create

    # Invitations
    resources "/invitations", InvitationController
    post "/invitations/:id/accept", AcceptInvitationController, :create
  end

  # GraphQL explorer
  scope "/" do
    pipe_through [:browser, :space]

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: LevelWeb.Schema,
      socket: LevelWeb.UserSocket,
      default_headers: {__MODULE__, :graphiql_headers},
      default_url: {__MODULE__, :graphiql_url}
  end

  def graphiql_headers(conn) do
    token = LevelWeb.Auth.generate_signed_jwt(conn.assigns.current_user)
    %{"Authorization" => "Bearer #{token}"}
  end

  def graphiql_url(conn) do
    URI.to_string(%URI{
      scheme: Atom.to_string(conn.scheme),
      port: conn.port,
      host: conn.host,
      path: "/graphql"
    })
  end

  # Space-scoped routes requiring authentication
  scope "/", LevelWeb do
    pipe_through [:browser, :space]

    get "/", CockpitController, :index
  end

  # RESTful API endpoints authenticated via browser cookies
  scope "/api", LevelWeb.API do
    pipe_through :browser_api
    resources "/tokens", UserTokenController, only: [:create]
  end

  scope "/api", LevelWeb.API do
    pipe_through [:browser_api, :csrf]

    resources "/spaces", SpaceController, only: [:create]
    post "/signup/errors", SignupErrorsController, :index

    resources "/tokens", UserTokenController, only: [:create]
  end

  # Preview sent emails in development mode
  if Mix.env() == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end
end
