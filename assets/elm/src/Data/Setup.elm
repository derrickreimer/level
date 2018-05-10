module Data.Setup exposing (State(..), setupStateDecoder, setupStateEncoder)

import Json.Decode as Decode
import Json.Encode as Encode


-- TYPES


type State
    = CreateGroups
    | InviteUsers
    | Complete



-- DECODERS


setupStateDecoder : Decode.Decoder State
setupStateDecoder =
    let
        convert : String -> Decode.Decoder State
        convert raw =
            case raw of
                "CREATE_GROUPS" ->
                    Decode.succeed CreateGroups

                "INVITE_USERS" ->
                    Decode.succeed InviteUsers

                "COMPLETE" ->
                    Decode.succeed Complete

                _ ->
                    Decode.fail "Setup state not valid"
    in
        Decode.string
            |> Decode.andThen convert



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
