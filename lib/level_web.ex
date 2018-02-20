defmodule LevelWeb do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use LevelWeb, :controller
      use LevelWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, namespace: LevelWeb

      alias Level.Repo
      import Ecto
      import Ecto.Query

      import LevelWeb.Router.Helpers
      import Level.Gettext

      import LevelWeb.Auth,
        only: [
          fetch_space: 2,
          fetch_current_user_by_session: 2,
          authenticate_with_token: 2,
          authenticate_user: 2
        ]

      import LevelWeb.Subdomain,
        only: [
          validate_host: 2,
          extract_subdomain: 2
        ]

      import LevelWeb.UrlHelpers
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/level_web/templates",
        namespace: LevelWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [
          get_csrf_token: 0,
          get_flash: 2,
          view_module: 1
        ]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import LevelWeb.Router.Helpers
      import LevelWeb.ErrorHelpers
      import Level.Gettext
      import LevelWeb.UrlHelpers
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import LevelWeb.Auth,
        only: [
          fetch_space: 2,
          fetch_current_user_by_session: 2,
          authenticate_with_token: 2,
          authenticate_user: 2
        ]

      import LevelWeb.Subdomain,
        only: [
          validate_host: 2,
          extract_subdomain: 2
        ]
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias Level.Repo
      import Ecto
      import Ecto.Query
      import Level.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
