defmodule Level.Pubsub do
  def publish(payload, topics) do
    Absinthe.Subscription.publish(LevelWeb.Endpoint, payload, topics)
  end
end
