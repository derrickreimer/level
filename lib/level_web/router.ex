defmodule LevelWeb.Router do
  @moduledoc false

  use LevelWeb, :router

  pipeline :anonymous_browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :authenticated_browser do
    plug :anonymous_browser
    plug :fetch_current_user_by_session
    plug :authenticate_user
  end

  pipeline :browser_api_without_csrf do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :put_secure_browser_headers
    plug :fetch_current_user_by_session
  end

  pipeline :graphql do
    plug :authenticate_with_token
  end

  scope "/" do
    pipe_through :graphql
    forward "/graphql", Absinthe.Plug, schema: LevelWeb.Schema
  end

  forward "/graphiql", Absinthe.Plug.GraphiQL,
    schema: LevelWeb.Schema,
    socket: LevelWeb.UserSocket,
    default_headers: {__MODULE__, :graphiql_headers},
    default_url: "/graphql"

  scope "/", LevelWeb do
    pipe_through :anonymous_browser

    get "/login", SessionController, :new
    post "/login", SessionController, :create

    get "/signup", UserController, :new
    post "/signup", UserController, :create
  end

  scope "/", LevelWeb do
    pipe_through :authenticated_browser

    resources "/spaces", SpaceController
    get "/", CockpitController, :index
  end

  scope "/api", LevelWeb.API do
    pipe_through :browser_api_without_csrf
    resources "/tokens", UserTokenController, only: [:create]
  end

  # Preview sent emails in development mode
  if Mix.env() == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end

  def graphiql_headers(conn) do
    case conn.assigns do
      %{current_user: user} ->
        token = LevelWeb.Auth.generate_signed_jwt(user)
        %{"Authorization" => "Bearer #{token}"}

      _ ->
        %{}
    end
  end
end
