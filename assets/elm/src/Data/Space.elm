module Data.Space exposing (Space, SpaceUserRole(..), spaceDecoder, spaceRoleDecoder)

import Json.Decode as Decode
import Json.Encode as Encode
import Json.Decode.Pipeline as Pipeline


-- TYPES


type alias Space =
    { id : String
    , name : String
    , slug : String
    }


type SpaceUserRole
    = Member
    | Owner



-- DECODERS


spaceDecoder : Decode.Decoder Space
spaceDecoder =
    Pipeline.decode Space
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "slug" Decode.string


spaceRoleDecoder : Decode.Decoder SpaceUserRole
spaceRoleDecoder =
    let
        convert : String -> Decode.Decoder SpaceUserRole
        convert raw =
            case raw of
                "MEMBER" ->
                    Decode.succeed Member

                "OWNER" ->
                    Decode.succeed Owner

                _ ->
                    Decode.fail "Space user role not valid"
    in
        Decode.string
            |> Decode.andThen convert
