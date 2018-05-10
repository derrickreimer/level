module Data.Space exposing (Space, SetupState(..), spaceDecoder, setupStateDecoder, setupStateEncoder)

import Json.Decode as Decode
import Json.Encode as Encode
import Json.Decode.Pipeline as Pipeline


-- TYPES


type alias Space =
    { id : String
    , name : String
    , slug : String
    , setupState : SetupState
    }


type SetupState
    = CreateGroups
    | InviteUsers
    | Complete



-- DECODERS


spaceDecoder : Decode.Decoder Space
spaceDecoder =
    Pipeline.decode Space
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "slug" Decode.string
        |> Pipeline.required "setupState" setupStateDecoder


setupStateDecoder : Decode.Decoder SetupState
setupStateDecoder =
    let
        convert : String -> Decode.Decoder SetupState
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


setupStateEncoder : SetupState -> Encode.Value
setupStateEncoder raw =
    case raw of
        CreateGroups ->
            Encode.string "CREATE_GROUPS"

        InviteUsers ->
            Encode.string "INVITE_USERS"

        Complete ->
            Encode.string "COMPLETE"
