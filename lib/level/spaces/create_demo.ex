defmodule Level.Spaces.CreateDemo do
  @moduledoc false

  alias Level.Groups
  alias Level.Posts
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.User
  alias Level.Spaces
  alias Level.Users

  @coffeekit_staff ["lisalatte", "joegibraltar", "sarahsinglepour", "kevincortado"]

  @spec perform(User.t()) :: {:ok, %{space: Space.t(), space_user: SpaceUser.t()}} | no_return()
  def perform(%User{} = user) do
    {:ok, %{space: space, space_user: space_user, default_group: everyone_group}} =
      create_space(user)

    # Add CoffeeKit staff to the space
    users = Users.get_users_by_handle(@coffeekit_staff)
    space_users = add_users_to_space(users, space)

    # Create some groups
    {:ok, %{group: engineering_group}} = Groups.create_group(space_user, %{name: "engineering"})
    {:ok, %{group: marketing_group}} = Groups.create_group(space_user, %{name: "marketing"})
    {:ok, %{group: sales_group}} = Groups.create_group(space_user, %{name: "sales"})
    {:ok, %{group: watercooler_group}} = Groups.create_group(space_user, %{name: "watercooler"})

    groups = %{
      "everyone" => everyone_group,
      "engineering" => engineering_group,
      "marketing" => marketing_group,
      "sales" => sales_group,
      "watercooler" => watercooler_group
    }

    # Create some posts
    create_retreat_post(space_users, groups)
    create_redesign_post(space_users, groups)
    create_watercooler_post(space_users, groups)

    {:ok, %{space: space, space_user: space_user}}
  end

  defp add_users_to_space(users, space) do
    users
    |> Enum.map(fn user -> add_user_to_space(user, space) end)
    |> Map.new()
  end

  defp add_user_to_space(user, space) do
    {:ok, space_user} = Spaces.create_member(user, space)
    {user.handle, space_user}
  end

  defp create_space(user) do
    params = %{
      name: "CoffeeKit",
      slug: "coffeekit-#{generate_salt()}",
      is_demo: true,
      avatar: "https://s3.amazonaws.com/level-assets-prod/demo/team-avatar.png"
    }

    Spaces.create_space(user, params, skip_welcome_message: true)
  end

  defp generate_salt do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode16()
    |> String.downcase()
  end

  defp create_retreat_post(space_users, groups) do
    {:ok, %{post: post}} =
      Posts.create_post(space_users["joegibraltar"], groups["everyone"], %{
        body: """
        Planning has begun for our annual retreat! First order of business, we need to figure out a location. Some ideas:

        ✈️ Costa Rica
        🌴 Los Angeles
        🍊 Miami
        🧔 Portland

        What's your favorite destination @#everyone?
        """
      })

    Posts.create_post_reaction(space_users["lisalatte"], post, "🎉")
    Posts.create_post_reaction(space_users["kevincortado"], post, "🎉")
    Posts.create_post_reaction(space_users["sarahsinglepour"], post, "😎")

    Posts.create_reply(space_users["lisalatte"], post, %{
      body:
        "I've always wanted to visit Costa Rica! Do we have the budget for international travel?"
    })

    {:ok, %{reply: reply}} =
      Posts.create_reply(space_users["joegibraltar"], post, %{
        body:
          "Good question! Accommodations might be a little more minimal if we go abroad. Definitely a tradeoff there."
      })

    Posts.create_reply_reaction(space_users["lisalatte"], post, reply, "👍")
  end

  defp create_redesign_post(space_users, groups) do
    {:ok, %{post: post}} =
      Posts.create_post(space_users["lisalatte"], groups["engineering"], %{
        body: """
        Hey engineers, I'm working on the new home page design and I will need a hand getting the split-testing JavaScript snippet put in place. Does anyone have time this week to assist?

        No rush, we're planning to ship the redesign next week. Let me know what information you need from me. Thanks!
        """
      })

    Posts.create_post_reaction(space_users["kevincortado"], post, "👍")

    {:ok, %{reply: reply}} =
      Posts.create_reply(space_users["kevincortado"], post, %{
        body:
          "I can help! The credentials should be in 1Password, but I'll let you know if I can't find the right ones."
      })

    Posts.create_reply_reaction(space_users["lisalatte"], post, reply, "🤜")
  end

  defp create_watercooler_post(space_users, groups) do
    {:ok, %{post: post}} =
      Posts.create_post(space_users["sarahsinglepour"], groups["watercooler"], %{
        body: """
        Question for the week: if you could choose to be any animal, which would you be and why?
        """
      })

    {:ok, %{reply: reply}} =
      Posts.create_reply(space_users["joegibraltar"], post, %{
        body: "A sloth. They seem really relaxed!"
      })

    Posts.create_reply_reaction(space_users["lisalatte"], post, reply, "😂")

    {:ok, %{reply: reply2}} =
      Posts.create_reply(space_users["kevincortado"], post, %{
        body: "Dog, because you're pretty much automatically everyone's friend."
      })

    Posts.create_reply_reaction(space_users["sarahsinglepour"], post, reply2, "🐶")
    Posts.create_reply_reaction(space_users["joegibraltar"], post, reply2, "🐶")

    {:ok, %{reply: reply3}} =
      Posts.create_reply(space_users["lisalatte"], post, %{
        body: "Dolphin, because I love swimming and being smart 😉"
      })

    Posts.create_reply_reaction(space_users["kevincortado"], post, reply3, "🐬")

    {:ok, %{reply: reply4}} =
      Posts.create_reply(space_users["sarahsinglepour"], post, %{
        body: "![Hmm](https://media.giphy.com/media/xUPGcmF2iGsTGEFVL2/giphy.gif)"
      })

    Posts.create_reply_reaction(space_users["kevincortado"], post, reply4, "😆")
    Posts.create_reply_reaction(space_users["lisalatte"], post, reply4, "😆")
    Posts.create_reply_reaction(space_users["joegibraltar"], post, reply4, "😆")
  end
end
