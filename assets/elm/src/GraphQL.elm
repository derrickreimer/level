module GraphQL exposing (query, payload, request)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Session exposing (Session)


query : List String -> String
query parts =
    parts
        |> List.map normalize
        |> String.join "\n"


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


normalize : String -> String
normalize value =
    let
        lines =
            value
                |> String.lines

        firstLine =
            lines
                |> List.head
                |> Maybe.withDefault ""

        tailPadding =
            lines
                |> List.tail
                |> Maybe.withDefault []
                |> List.map String.toList
                |> List.map (countPadding 0)
                |> List.minimum
                |> Maybe.withDefault 0
    in
        lines
            |> List.tail
            |> Maybe.withDefault []
            |> List.map (String.dropLeft tailPadding)
            |> (::) firstLine
            |> String.join "\n"


countPadding : Int -> List Char -> Int
countPadding count list =
    case list of
        [ ' ' ] ->
            count + 1

        ' ' :: tl ->
            countPadding (count + 1) tl

        _ ->
            count
