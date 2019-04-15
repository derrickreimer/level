# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Level.Repo.insert!(%Level.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Level.Levelbot
alias Level.Postbot
alias Level.Users

# Create bots
Levelbot.create_bot!()
Postbot.create_bot!()

# Create demo users
{:ok, _} =
  Users.create_user(%{
    email: "joe@coffeekit.app",
    handle: "joegibraltar",
    first_name: "Joe",
    last_name: "Gibraltar",
    has_password: false,
    is_demo: true,
    time_zone: "America/Chicago",
    avatar: "https://s3.amazonaws.com/level-assets-prod/demo/joe-avatar.jpg"
  })

{:ok, _} =
  Users.create_user(%{
    email: "sarah@coffeekit.app",
    handle: "sarahsinglepour",
    first_name: "Sarah",
    last_name: "Singlepour",
    has_password: false,
    is_demo: true,
    time_zone: "America/Chicago",
    avatar: "https://s3.amazonaws.com/level-assets-prod/demo/sarah-avatar.jpg"
  })

{:ok, _} =
  Users.create_user(%{
    email: "lisa@coffeekit.app",
    handle: "lisalatte",
    first_name: "Lisa",
    last_name: "Latte",
    has_password: false,
    is_demo: true,
    time_zone: "America/Chicago",
    avatar: "https://s3.amazonaws.com/level-assets-prod/demo/lisa-avatar.jpg"
  })

{:ok, _} =
  Users.create_user(%{
    email: "kevin@coffeekit.app",
    handle: "kevincortado",
    first_name: "Kevin",
    last_name: "Cortado",
    has_password: false,
    is_demo: true,
    time_zone: "America/Chicago",
    avatar: "https://s3.amazonaws.com/level-assets-prod/demo/kevin-avatar.jpg"
  })
