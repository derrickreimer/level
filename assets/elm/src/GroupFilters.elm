module GroupFilters exposing (hasUnreads)

import Group exposing (Group)
import InboxStateFilter
import Post exposing (Post)
import Repo exposing (Repo)


{-| Determines if a channel has any unread posts.
-}
hasUnreads : Repo -> Group -> Bool
hasUnreads repo group =
    repo
        |> Repo.getPostsByGroup (Group.id group) Nothing
        |> List.filter (Post.withInboxState InboxStateFilter.Unread)
        |> List.isEmpty
        |> not
