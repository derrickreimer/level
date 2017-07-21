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
    plug :fetch_team
    plug :fetch_current_user_by_session
    plug :authenticate_user
  end

  pipeline :browser_api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :validate_host
    plug :extract_subdomain
  end

  pipeline :graphql do
    plug :validate_host
    plug :extract_subdomain
    plug :fetch_team
    plug :authenticate_with_token
  end

  # GraphQL API
  scope "/" do
    pipe_through :graphql
    forward "/graphql", Absinthe.Plug, schema: Bridge.Web.Schema
  end

  # Launcher-scoped routes
  scope "/", Bridge.Web, host: "launch." do
    pipe_through :browser # Use the default browser stack

    get "/", TeamController, :index
    get "/teams/new", TeamController, :new
    get "/teams/search", TeamSearchController, :new
    post "/teams/search", TeamSearchController, :create
  end

  # Team-scoped routes not requiring authentication
  scope "/", Bridge.Web do
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
    pipe_through [:browser, :team]
    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: Bridge.Web.Schema,
      default_headers: &__MODULE__.graphiql_headers/1,
      default_url: &__MODULE__.graphiql_url/1
  end

  def graphiql_headers(conn) do
    token = Bridge.Web.Auth.generate_signed_jwt(conn.assigns.current_user)
    %{"Authorization" => "Bearer #{token}"}
  end

  def graphiql_url(conn) do
    URI.to_string %URI{
      scheme: Atom.to_string(conn.scheme),
      port: conn.port,
      host: conn.host,
      path: "/graphql"
    }
  end

  # Team-scoped routes requiring authentication
  scope "/", Bridge.Web do
    pipe_through [:browser, :team]

    get "/", ThreadController, :index
  end

  # RESTful API endpoints authenticated via browser cookies
  scope "/api", Bridge.Web.API do
    pipe_through :browser_api

    resources "/teams", TeamController, only: [:create]
    post "/signup/errors", SignupErrorsController, :index

    resources "/user_tokens", UserTokenController, only: [:create]
  end
end
