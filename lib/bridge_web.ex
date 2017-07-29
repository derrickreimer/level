defmodule BridgeWeb do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use BridgeWeb, :controller
      use BridgeWeb, :view

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
      use Phoenix.Controller, namespace: BridgeWeb

      alias Bridge.Repo
      import Ecto
      import Ecto.Query

      import BridgeWeb.Router.Helpers
      import BridgeWeb.Gettext

      import BridgeWeb.Auth, only: [
        fetch_team: 2,
        fetch_current_user_by_session: 2,
        authenticate_with_token: 2,
        authenticate_user: 2
      ]

      import BridgeWeb.Subdomain, only: [
        validate_host: 2,
        extract_subdomain: 2
      ]

      import BridgeWeb.UrlHelpers
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/bridge_web/templates",
                        namespace: BridgeWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [
        get_csrf_token: 0,
        get_flash: 2,
        view_module: 1
      ]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import BridgeWeb.Router.Helpers
      import BridgeWeb.ErrorHelpers
      import BridgeWeb.Gettext
      import BridgeWeb.UrlHelpers
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import BridgeWeb.Auth, only: [
        fetch_team: 2,
        fetch_current_user_by_session: 2,
        authenticate_with_token: 2,
        authenticate_user: 2
      ]

      import BridgeWeb.Subdomain, only: [
        validate_host: 2,
        extract_subdomain: 2
      ]
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias Bridge.Repo
      import Ecto
      import Ecto.Query
      import BridgeWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
