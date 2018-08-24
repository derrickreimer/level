module Setup exposing (State(..), routeFor, setupStateDecoder, setupStateEncoder)

import Json.Decode as Decode exposing (Decoder, fail, string, succeed)
import Json.Encode as Encode
import Route exposing (Route)
import Space exposing (Space)



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


routeFor : Space -> State -> Route
routeFor space state =
    let
        slug =
            Space.getSlug space
    in
    case state of
        CreateGroups ->
            Route.SetupCreateGroups slug

        InviteUsers ->
            Route.SetupInviteUsers slug

        Complete ->
            Route.Inbox slug
