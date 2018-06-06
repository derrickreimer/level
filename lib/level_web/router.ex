defmodule LevelWeb.Router do
  @moduledoc false

  use LevelWeb, :router

  pipeline :anonymous_browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user_by_session
  end

  pipeline :authenticated_browser do
    plug :anonymous_browser
    plug :redirect_unless_signed_in
  end

  pipeline :browser_api_without_csrf do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :put_secure_browser_headers
    plug :fetch_current_user_by_session
  end

  pipeline :graphql do
    plug :fetch_current_user_by_token
    plug :put_absinthe_context
  end

  scope "/" do
    pipe_through :graphql
    forward "/graphql", Absinthe.Plug, schema: LevelWeb.Schema
  end

  scope "/", LevelWeb do
    pipe_through :anonymous_browser

    get "/", PageController, :index
    get "/manifesto", PageController, :manifesto

    get "/login", SessionController, :new
    post "/login", SessionController, :create

    get "/signup", UserController, :new
    post "/signup", UserController, :create

    get "/invites/:id", OpenInvitationController, :show
    post "/invites/:id/accept", OpenInvitationController, :accept
  end

  scope "/" do
    pipe_through [
      :anonymous_browser,
      :fetch_current_user_by_session,
      :redirect_unless_signed_in
    ]

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: LevelWeb.Schema,
      socket: LevelWeb.UserSocket,
      default_headers: {__MODULE__, :graphiql_headers},
      default_url: "/graphql"
  end

  scope "/api", LevelWeb.API do
    pipe_through :browser_api_without_csrf
    resources "/tokens", UserTokenController, only: [:create]
    resources "/reservations", ReservationController, only: [:create]
  end

  # Preview sent emails in development mode
  if Mix.env() == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end

  scope "/", LevelWeb do
    pipe_through :authenticated_browser

    get "/spaces", SpaceController, :index
    get "/spaces/new", SpaceController, :new

    # Important: this must be the last route defined
    get "/:slug", SpaceController, :show
  end

  def graphiql_headers(conn) do
    case conn.assigns do
      %{current_user: user} ->
        token = generate_token(user)
        %{"Authorization" => "Bearer #{token}"}

      _ ->
        %{}
    end
  end

  def generate_token(user) do
    case Mix.env() do
      :dev ->
        LevelWeb.Auth.generate_signed_jwt(user, 604_800 * 52)

      _ ->
        LevelWeb.Auth.generate_signed_jwt(user)
    end
  end
end
