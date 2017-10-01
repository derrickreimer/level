defmodule LevelWeb.SpaceView do
  use LevelWeb, :view

  def space_host(space) do
    "#{space.slug}.#{default_host()}"
  end
end
