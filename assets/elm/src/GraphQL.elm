module GraphQL exposing (Payload, encodePayload, request)

import Http
import Json.Encode as Encode
import Json.Decode as Decode


type alias Payload =
    { query : String
    , variables : Maybe Encode.Value
    }


encodePayload : Payload -> Encode.Value
encodePayload payload =
    case payload.variables of
        Nothing ->
            Encode.object
                [ ( "query", Encode.string payload.query ) ]

        Just variables ->
            Encode.object
                [ ( "query", Encode.string payload.query )
                , ( "variables", variables )
                ]


request : String -> Payload -> Decode.Decoder a -> Http.Request a
request apiToken payload decoder =
    Http.request
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Bearer " ++ apiToken) ]
        , url = "/graphql"
        , body = Http.stringBody "application/json" (Encode.encode 0 (encodePayload payload))
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }
