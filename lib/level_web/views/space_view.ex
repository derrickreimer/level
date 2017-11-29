defmodule LevelWeb.SpaceView do
  @moduledoc false

  use LevelWeb, :view

  def space_host(space) do
    "#{space.slug}.#{default_host()}"
  end
end
