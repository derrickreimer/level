module Data.GroupMembership
    exposing
        ( GroupMembership
        , GroupMembershipState(..)
        , decoder
        , stateDecoder
        , stateEncoder
        )

import Json.Decode as Decode exposing (Decoder, field, string, succeed, fail)
import Json.Encode as Encode
import Data.SpaceUser exposing (SpaceUser)


-- TYPES


type alias GroupMembership =
    { user : SpaceUser
    }


type GroupMembershipState
    = NotSubscribed
    | Subscribed



-- DECODERS


decoder : Decoder GroupMembership
decoder =
    Decode.map GroupMembership
        (field "spaceUser" Data.SpaceUser.decoder)


stateDecoder : Decoder GroupMembershipState
stateDecoder =
    let
        convert : String -> Decoder GroupMembershipState
        convert raw =
            case raw of
                "SUBSCRIBED" ->
                    succeed Subscribed

                "NOT_SUBSCRIBED" ->
                    succeed NotSubscribed

                _ ->
                    fail "Membership state not valid"
    in
        Decode.andThen convert string



-- ENCODERS


stateEncoder : GroupMembershipState -> Encode.Value
stateEncoder state =
    case state of
        NotSubscribed ->
            Encode.string "NOT_SUBSCRIBED"

        Subscribed ->
            Encode.string "SUBSCRIBED"
