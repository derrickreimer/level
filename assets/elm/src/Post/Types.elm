module Post.Types exposing (Data, InboxState(..), State(..), SubscriptionState(..), decoder, decoderWithReplies, fragment)

import Connection exposing (Connection)
import GraphQL exposing (Fragment)
import Group exposing (Group)
import Json.Decode as Decode exposing (Decoder, fail, field, int, list, string, succeed)
import Json.Decode.Pipeline as Pipeline exposing (required)
import Mention exposing (Mention)
import Reply exposing (Reply)
import SpaceUser exposing (SpaceUser)
import Time exposing (Posix)
import Tuple
import Util exposing (dateDecoder)



-- TYPES


type State
    = Open
    | Closed


type SubscriptionState
    = NotSubscribed
    | Subscribed
    | Unsubscribed


type InboxState
    = Excluded
    | Dismissed
    | Read
    | Unread


type alias Data =
    { id : String
    , state : State
    , body : String
    , bodyHtml : String
    , authorId : String
    , groupIds : List String
    , postedAt : Posix
    , subscriptionState : SubscriptionState
    , inboxState : InboxState
    , fetchedAt : Int
    }



-- GRAPHQL


fragment : Fragment
fragment =
    let
        body =
            """
            fragment PostFields on Post {
              id
              state
              body
              bodyHtml
              postedAt
              subscriptionState
              inboxState
              author {
                ...SpaceUserFields
              }
              groups {
                ...GroupFields
              }
              fetchedAt
            }
            """
    in
    GraphQL.toFragment body
        [ SpaceUser.fragment
        , Group.fragment
        , Mention.fragment
        ]



-- DECODERS


decoder : Decoder Data
decoder =
    Decode.succeed Data
        |> required "id" string
        |> required "state" stateDecoder
        |> required "body" string
        |> required "bodyHtml" string
        |> required "author" (field "id" string)
        |> required "groups" (list (field "id" string))
        |> required "postedAt" dateDecoder
        |> required "subscriptionState" subscriptionStateDecoder
        |> required "inboxState" inboxStateDecoder
        |> required "fetchedAt" int


decoderWithReplies : Decoder ( Data, Connection Reply )
decoderWithReplies =
    Decode.map2 Tuple.pair decoder (field "replies" (Connection.decoder Reply.decoder))


stateDecoder : Decoder State
stateDecoder =
    let
        convert : String -> Decoder State
        convert raw =
            case raw of
                "OPEN" ->
                    succeed Open

                "CLOSED" ->
                    succeed Closed

                _ ->
                    fail "State not valid"
    in
    Decode.andThen convert string


subscriptionStateDecoder : Decoder SubscriptionState
subscriptionStateDecoder =
    let
        convert : String -> Decoder SubscriptionState
        convert raw =
            case raw of
                "SUBSCRIBED" ->
                    succeed Subscribed

                "UNSUBSCRIBED" ->
                    succeed Unsubscribed

                "NOT_SUBSCRIBED" ->
                    succeed NotSubscribed

                _ ->
                    fail "Subscription state not valid"
    in
    Decode.andThen convert string


inboxStateDecoder : Decoder InboxState
inboxStateDecoder =
    let
        convert : String -> Decoder InboxState
        convert raw =
            case raw of
                "EXCLUDED" ->
                    succeed Excluded

                "DISMISSED" ->
                    succeed Dismissed

                "READ" ->
                    succeed Read

                "UNREAD" ->
                    succeed Unread

                _ ->
                    fail "Inbox state not valid"
    in
    Decode.andThen convert string
