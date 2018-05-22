module Socket exposing (Payload)

import Json.Encode as Encode


-- TYPES


type alias Payload =
    { clientId : String
    , operation : String
    , variables : Maybe Encode.Value
    }
