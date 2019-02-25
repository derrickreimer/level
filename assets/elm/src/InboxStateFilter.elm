module InboxStateFilter exposing (InboxStateFilter(..), fromQuery, toEnum, toQuery)


type InboxStateFilter
    = Undismissed
    | Dismissed
    | Unread
    | All


fromQuery : Maybe String -> InboxStateFilter
fromQuery value =
    case value of
        Just "undismissed" ->
            Undismissed

        Just "dismissed" ->
            Dismissed

        Just "unread" ->
            Unread

        _ ->
            All


toQuery : InboxStateFilter -> Maybe String
toQuery value =
    case value of
        Undismissed ->
            Just "undismissed"

        Dismissed ->
            Just "dismissed"

        Unread ->
            Just "unread"

        All ->
            Nothing


toEnum : InboxStateFilter -> String
toEnum value =
    case value of
        Undismissed ->
            "UNDISMISSED"

        Dismissed ->
            "DISMISSED"

        Unread ->
            "UNREAD"

        All ->
            "ALL"
