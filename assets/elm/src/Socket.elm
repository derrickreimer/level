module Socket exposing (Payload, payload)

import Json.Encode as Encode
import GraphQL exposing (Document, serializeDocument)


-- TYPES


type alias Payload =
    { clientId : String
    , operation : String
    , variables : Maybe Encode.Value
    }


payload : String -> Document -> Maybe Encode.Value -> Payload
payload clientId document maybeVariables =
    Payload clientId (serializeDocument document) maybeVariables
