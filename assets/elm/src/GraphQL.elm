module GraphQL exposing (query, payload, request)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Session exposing (Session)


query : List String -> String
query parts =
    String.join "\n\n" parts


payload : List String -> Maybe Encode.Value -> Encode.Value
payload queryParts maybeVariables =
    case maybeVariables of
        Nothing ->
            Encode.object
                [ ( "query", Encode.string (query queryParts) ) ]

        Just variables ->
            Encode.object
                [ ( "query", Encode.string (query queryParts) )
                , ( "variables", variables )
                ]


request : List String -> Maybe Encode.Value -> Decode.Decoder a -> Session -> Http.Request a
request queryParts maybeVariables decoder session =
    let
        body =
            Encode.encode 0 (payload queryParts maybeVariables)
    in
        Http.request
            { method = "POST"
            , headers = [ Http.header "Authorization" ("Bearer " ++ session.token) ]
            , url = "/graphql"
            , body = Http.stringBody "application/json" body
            , expect = Http.expectJson decoder
            , timeout = Nothing
            , withCredentials = False
            }
