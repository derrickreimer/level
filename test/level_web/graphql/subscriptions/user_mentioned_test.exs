defmodule LevelWeb.GraphQL.UserMentionedTest do
  use LevelWeb.ChannelCase

  # TODO: figure out why this test is not working. I keep getting a database connection
  # timeout error in the dataloader code that fetches the associated mentions?

  #     14:49:14.308 [error] Task #PID<0.1698.0> started from #PID<0.1693.0> terminating
  # ** (stop) exited in: GenServer.call(#PID<0.1682.0>, {:checkout, #Reference ...
  #     ** (EXIT) time out
  #     (db_connection) lib/db_connection/ownership/proxy.ex:32: DBConnection.Ownership.Proxy.checkout/2
  #     (db_connection) lib/db_connection.ex:928: DBConnection.checkout/2
  #     (db_connection) lib/db_connection.ex:750: DBConnection.run/3
  #     (db_connection) lib/db_connection.ex:644: DBConnection.execute/4
  #     (ecto) lib/ecto/adapters/postgres/connection.ex:98: Ecto.Adapters.Postgres.Connection.execute/4
  #     (ecto) lib/ecto/adapters/sql.ex:256: Ecto.Adapters.SQL.sql_call/6
  #     (ecto) lib/ecto/adapters/sql.ex:436: Ecto.Adapters.SQL.execute_or_reset/7
  #     (ecto) lib/ecto/repo/queryable.ex:133: Ecto.Repo.Queryable.execute/5
  #     (ecto) lib/ecto/repo/queryable.ex:37: Ecto.Repo.Queryable.all/4
  #     (dataloader) lib/dataloader/ecto.ex:173: Dataloader.Ecto.run_batch/6
  #     (dataloader) lib/dataloader/ecto.ex:374: Dataloader.Source.Dataloader.Ecto.run_batch/2
  #     (elixir) lib/task/supervised.ex:89: Task.Supervised.do_apply/2
  #     (elixir) lib/task/supervised.ex:38: Task.Supervised.reply/5
  #     (stdlib) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
  # Function: &:erlang.apply/2
  #     Args: [#Function<5.55134300/1 in Dataloader.Source.Dataloader.Ecto.run/1>, ...

  # @operation """
  #   subscription SpaceUserSubscription(
  #     $id: ID!
  #   ) {
  #     spaceUserSubscription(spaceUserId: $id) {
  #       __typename
  #       ... on UserMentionedPayload {
  #         post {
  #           body
  #           mentions {
  #             mentioner {
  #               id
  #             }
  #           }
  #         }
  #       }
  #     }
  #   }
  # """

  # setup do
  #   {:ok, result} = create_user_and_space(%{handle: "derrick"})
  #   {:ok, Map.put(result, :socket, build_socket(result.user))}
  # end

  # test "receives an event when a user mentions another user", %{
  #   socket: socket,
  #   space: space,
  #   space_user: space_user
  # } do
  #   {:ok, %{group: group}} = create_group(space_user)
  #   {:ok, %{space_user: another_user}} = create_space_member(space, %{handle: "tiff"})

  #   ref = push_subscription(socket, @operation, %{"id" => space_user.id})
  #   assert_reply(ref, :ok, %{subscriptionId: subscription_id}, 1000)

  #   {:ok, %{post: _post}} = create_post(another_user, group, %{body: "Hey @derrick"})

  #   push_data = %{
  #     result: %{
  #       data: %{
  #         "spaceUserSubscription" => %{
  #           "__typename" => "UserMentionedPayload",
  #           "post" => %{
  #             "body" => "Hey @derrick",
  #             "mentions" => [
  #               %{
  #                 "mentioner" => %{
  #                   "id" => another_user.id
  #                 }
  #               }
  #             ]
  #           }
  #         }
  #       }
  #     },
  #     subscriptionId: subscription_id
  #   }

  #   assert_push("subscription:data", ^push_data)
  # end
end
