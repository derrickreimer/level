module Post exposing (Post, Record, State(..), SubscriptionState(..), decoder, decoderWithReplies, fragment, getCachedData, getId, groupsInclude)

import Connection exposing (Connection)
import GraphQL exposing (Fragment)
import Group exposing (Group)
import Json.Decode as Decode exposing (Decoder, fail, field, int, list, string, succeed)
import Json.Decode.Pipeline as Pipeline
import Mention exposing (Mention)
import Reply exposing (Reply)
import SpaceUser exposing (SpaceUser)
import Time exposing (Posix)
import Tuple
import Util exposing (dateDecoder)



-- TYPES


type Post
    = Post Record


type State
    = Open
    | Closed


type SubscriptionState
    = NotSubscribed
    | Subscribed
    | Unsubscribed


type alias Record =
    { id : String
    , state : State
    , body : String
    , bodyHtml : String
    , author : SpaceUser
    , groups : List Group
    , postedAt : Posix
    , subscriptionState : SubscriptionState
    , mentions : List Mention
    , fetchedAt : Int
    }


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
              author {
                ...SpaceUserFields
              }
              groups {
                ...GroupFields
              }
              mentions {
                ...MentionFields
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


decoder : Decoder Post
decoder =
    Decode.map Post <|
        (Decode.succeed Record
            |> Pipeline.required "id" string
            |> Pipeline.required "state" stateDecoder
            |> Pipeline.required "body" string
            |> Pipeline.required "bodyHtml" string
            |> Pipeline.required "author" SpaceUser.decoder
            |> Pipeline.required "groups" (list Group.decoder)
            |> Pipeline.required "postedAt" dateDecoder
            |> Pipeline.required "subscriptionState" subscriptionStateDecoder
            |> Pipeline.required "mentions" (list Mention.decoder)
            |> Pipeline.required "fetchedAt" int
        )


decoderWithReplies : Decoder ( Post, Connection Reply )
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



-- CRUD


getId : Post -> String
getId (Post { id }) =
    id


getCachedData : Post -> Record
getCachedData (Post data) =
    data


groupsInclude : Group -> Post -> Bool
groupsInclude group (Post data) =
    List.filter (\g -> Group.getId g == Group.getId group) data.groups
        |> List.isEmpty
        |> not
