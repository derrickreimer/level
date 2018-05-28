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
        , add
        , remove
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
        convert : String -> Decode.Decoder GroupMembershipState
        convert raw =
            case raw of
                "SUBSCRIBED" ->
                    Decode.succeed Subscribed

                "NOT_SUBSCRIBED" ->
                    Decode.succeed NotSubscribed

                _ ->
                    Decode.fail "Membership state not valid"
    in
        Decode.string
            |> Decode.andThen convert



-- ENCODERS


groupMembershipStateEncoder : GroupMembershipState -> Encode.Value
groupMembershipStateEncoder state =
    case state of
        NotSubscribed ->
            Encode.string "NOT_SUBSCRIBED"

        Subscribed ->
            Encode.string "SUBSCRIBED"



-- MUTATIONS


add : GroupMembership -> GroupMembershipConnection -> GroupMembershipConnection
add membership connection =
    let
        edges =
            connection.edges
    in
        if List.any (\{ node } -> node.user.id == membership.user.id) edges then
            connection
        else
            { connection | edges = (GroupMembershipEdge membership) :: edges }


remove : GroupMembership -> GroupMembershipConnection -> GroupMembershipConnection
remove membership connection =
    let
        newEdges =
            connection.edges
                |> List.filter (\{ node } -> not (node.user.id == membership.user.id))
    in
        { connection | edges = newEdges }
