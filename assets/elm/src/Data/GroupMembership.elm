module Data.GroupMembership
    exposing
        ( GroupMembership
        , GroupMembershipConnection
        , GroupMembershipEdge
        , GroupMembershipState(..)
        , groupMembershipDecoder
        , groupMembershipConnectionDecoder
        , groupMembershipStateDecoder
        , groupMembershipStateEncoder
        )

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
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


type GroupMembershipState
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


groupMembershipStateDecoder : Decode.Decoder GroupMembershipState
groupMembershipStateDecoder =
    let
        convert : Maybe String -> Decode.Decoder GroupMembershipState
        convert raw =
            case raw of
                Just "SUBSCRIBED" ->
                    Decode.succeed Subscribed

                Just _ ->
                    Decode.fail "Subscription level not valid"

                Nothing ->
                    Decode.succeed NotSubscribed
    in
        Decode.maybe (Decode.field "state" Decode.string)
            |> Decode.andThen convert



-- ENCODERS


groupMembershipStateEncoder : GroupMembershipState -> Encode.Value
groupMembershipStateEncoder state =
    case state of
        NotSubscribed ->
            Encode.string "NOT_SUBSCRIBED"

        Subscribed ->
            Encode.string "SUBSCRIBED"
