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
    {:ok,
     %{space: space, space_user: space_user, default_group: everyone_group, levelbot: levelbot}} =
      create_space(user)

    # Add CoffeeKit staff to the space
    users = Users.get_users_by_handle(@coffeekit_staff)
    space_users = add_users_to_space(users, space)

    # Create some groups
    {:ok, %{group: engineering_group}} = Groups.create_group(space_user, %{name: "engineering"})
    {:ok, %{group: watercooler_group}} = Groups.create_group(space_user, %{name: "watercooler"})

    groups = %{
      "everyone" => everyone_group,
      "engineering" => engineering_group,
      "watercooler" => watercooler_group
    }

    # Create some posts
    create_retreat_post(space_users, groups)
    create_redesign_post(space_users, groups)
    create_watercooler_post(space_users, groups)
    create_engineering_proposal_post(space_users, groups)

    # Create levelbot welcome message
    create_welcome_message(levelbot, space_user)

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

  defp create_engineering_proposal_post(space_users, groups) do
    {:ok, %{post: post}} =
      Posts.create_post(space_users["kevincortado"], groups["engineering"], %{
        body: """
        ## Caching expensive queries to improve performance

        @sarahsinglepour and I have been digging into New Relic to identify areas of the app that are particularly slow.

        In the process, we identified a number of queries hitting Postgres that have 6+ JOINs and can take up to 10s to run. Yikes.

        The good news is I believe the results of these particular queries could be cached in Redis (or some other in-memory store?) pretty easily. The results can be up to ~1 hour stale without violating user expectations.

        Rough estimate is 1 week to stand up some new caching infrastructure and implementing the domain logic.

        Some open questions at this point:

        - Anyone have strong preferences on the data store we use?
        - Customers are definitely feeling the pain. How high should we prioritize this? (/cc @lisalatte)
        """
      })

    {:ok, %{reply: reply}} =
      Posts.create_reply(space_users["lisalatte"], post, %{
        body:
          "Customer impact is indeed high. My sense is that this should come first in our next work cycle. I will defer to others on the question of data store."
      })

    {:ok, %{reply: reply2}} =
      Posts.create_reply(space_users["joegibraltar"], post, %{
        body:
          "Re: datastore, I come down between Redis and Memcached. I'm partial to Redis because it has a pretty big library of data structures that might be useful (e.g. sets)."
      })

    Posts.create_reply_reaction(space_users["sarahsinglepour"], post, reply2, "👍")

    {:ok, %{reply: reply3}} =
      Posts.create_reply(space_users["sarahsinglepour"], post, %{
        body:
          "Agreed on Redis. There are variety of hosted options too (Redis Labs, AWS, Compose, etc.)"
      })

    Posts.create_reply_reaction(space_users["joegibraltar"], post, reply3, "👍")
  end

  defp create_welcome_message(levelbot, owner) do
    body = """
    # Welcome to the CoffeeKit demo team

    Hi @#{owner.handle} 👋

    CoffeeKit is a fictitious software company using Level to organize their communication.

    Feel free to click around a bit to get a feel for the product!

    If you're coming from real-time chat, there are a few key differences to note:

    - Conversations are always threaded.
    - The Inbox queues up important messages for you until you take action.
    - Push notifications are batched up to protect your focus.
    - There are no presence indicators falsely indicating someone is available.

    When you're ready, **[click here to create your own team →](/teams/new)**
    """

    Posts.create_post(levelbot, %{body: body, display_name: "Level"})
  end
end
