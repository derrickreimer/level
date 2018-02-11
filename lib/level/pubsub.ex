defmodule Level.Pubsub do
  @moduledoc """
  This module encapsulates behavior for publishing messages to listeners
  (such as Absinthe GraphQL subscriptions).
  """

  def publish(payload, topics) do
    Absinthe.Subscription.publish(LevelWeb.Endpoint, payload, topics)
  end
end
