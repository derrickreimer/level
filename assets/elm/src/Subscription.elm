module Subscription exposing (cancel, decoder, genericDecoder, send)

import GraphQL exposing (Document, serializeDocument)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Socket


send : String -> Document -> Maybe Encode.Value -> Cmd msg
send clientId document maybeVariables =
    let
        encodedVariables =
            case maybeVariables of
                Just variables ->
                    variables

                Nothing ->
                    Encode.null
    in
    Socket.send <|
        Encode.object
            [ ( "method", Encode.string "sendSubscription" )
            , ( "clientId", Encode.string clientId )
            , ( "operation", Encode.string (serializeDocument document) )
            , ( "variables", encodedVariables )
            ]


cancel : String -> Cmd msg
cancel clientId =
    Socket.send <|
        Encode.object
            [ ( "method", Encode.string "cancelSubscription" )
            , ( "clientId", Encode.string clientId )
            ]


decoder : String -> String -> String -> Decoder a -> Decoder a
decoder topic event nodeType nodeDecoder =
    let
        payloadDecoder typename =
            if typename == (event ++ "Payload") then
                Decode.field nodeType nodeDecoder

            else
                Decode.fail "payload does not match"
    in
    Decode.field (topic ++ "Subscription") <|
        (Decode.field "__typename" Decode.string
            |> Decode.andThen payloadDecoder
        )


genericDecoder : String -> String -> Decoder a -> Decoder a
genericDecoder topic event resultDecoder =
    let
        payloadDecoder typename =
            if typename == (event ++ "Payload") then
                resultDecoder

            else
                Decode.fail "payload does not match"
    in
    Decode.field (topic ++ "Subscription") <|
        (Decode.field "__typename" Decode.string
            |> Decode.andThen payloadDecoder
        )
