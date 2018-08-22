module Setup exposing (State(..), routeFor, setupStateDecoder, setupStateEncoder)

import Json.Decode as Decode exposing (Decoder, fail, string, succeed)
import Json.Encode as Encode
import Route exposing (Route)



-- TYPES


type State
    = CreateGroups
    | InviteUsers
    | Complete



-- DECODERS


setupStateDecoder : Decoder State
setupStateDecoder =
    let
        convert : String -> Decoder State
        convert raw =
            case raw of
                "CREATE_GROUPS" ->
                    succeed CreateGroups

                "INVITE_USERS" ->
                    succeed InviteUsers

                "COMPLETE" ->
                    succeed Complete

                _ ->
                    fail "Setup state not valid"
    in
    Decode.andThen convert string



-- ENCODERS


setupStateEncoder : State -> Encode.Value
setupStateEncoder raw =
    case raw of
        CreateGroups ->
            Encode.string "CREATE_GROUPS"

        InviteUsers ->
            Encode.string "INVITE_USERS"

        Complete ->
            Encode.string "COMPLETE"



-- ROUTING


routeFor : State -> Route
routeFor state =
    case state of
        CreateGroups ->
            Route.SetupCreateGroups

        InviteUsers ->
            Route.SetupInviteUsers

        Complete ->
            Route.Inbox
