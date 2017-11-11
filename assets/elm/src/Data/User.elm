module Data.User exposing (User, userDecoder, displayName)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline


-- TYPES


type alias User =
    { id : String
    , firstName : String
    , lastName : String
    }



-- DECODERS


userDecoder : Decode.Decoder User
userDecoder =
    Pipeline.decode User
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "firstName" Decode.string
        |> Pipeline.required "lastName" Decode.string



-- UTILS


{-| Generate the display name for a given user.

    displayName { firstName = "Derrick", lastName = "Reimer" } == "Derrick Reimer"

-}
displayName : User -> String
displayName user =
    user.firstName ++ " " ++ user.lastName
