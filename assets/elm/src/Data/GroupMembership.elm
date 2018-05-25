module Data.GroupMembership
    exposing
        ( GroupMembership
        , GroupMembershipConnection
        , GroupMembershipEdge
        , GroupSubscriptionLevel(..)
        , groupMembershipDecoder
        , groupMembershipConnectionDecoder
        , groupSubscriptionLevelDecoder
        )

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Data.PageInfo exposing (PageInfo, pageInfoDecoder)
import Data.SpaceUser exposing (SpaceUser, spaceUserDecoder)


-- TYPES


type alias GroupMembershipConnection =
    { edges : List GroupMembershipEdge
    , pageInfo : PageInfo
    }


type alias GroupMembershipEdge =
    { node : GroupMembership
    }


type alias GroupMembership =
    { user : SpaceUser
    }


type GroupSubscriptionLevel
    = NotSubscribed
    | Subscribed



-- DECODERS


groupMembershipConnectionDecoder : Decode.Decoder GroupMembershipConnection
groupMembershipConnectionDecoder =
    Pipeline.decode GroupMembershipConnection
        |> Pipeline.custom (Decode.at [ "edges" ] (Decode.list groupMembershipEdgeDecoder))
        |> Pipeline.custom (Decode.at [ "pageInfo" ] pageInfoDecoder)


groupMembershipEdgeDecoder : Decode.Decoder GroupMembershipEdge
groupMembershipEdgeDecoder =
    Pipeline.decode GroupMembershipEdge
        |> Pipeline.custom (Decode.at [ "node" ] groupMembershipDecoder)


groupMembershipDecoder : Decode.Decoder GroupMembership
groupMembershipDecoder =
    Pipeline.decode GroupMembership
        |> Pipeline.required "spaceUser" spaceUserDecoder


groupSubscriptionLevelDecoder : Decode.Decoder GroupSubscriptionLevel
groupSubscriptionLevelDecoder =
    let
        convert : Maybe String -> Decode.Decoder GroupSubscriptionLevel
        convert raw =
            case raw of
                Just "SUBSCRIBED" ->
                    Decode.succeed Subscribed

                Just _ ->
                    Decode.fail "Subscription level not valid"

                Nothing ->
                    Decode.succeed NotSubscribed
    in
        Decode.maybe (Decode.field "subscriptionLevel" Decode.string)
            |> Decode.andThen convert
