module KeyboardShortcuts exposing (subscribe)

import Browser.Events
import Json.Decode as Decode exposing (Decoder, fail, field, string, succeed)


type alias Shortcuts msg =
    List ( String, msg )



-- API


subscribe : Shortcuts msg -> Sub msg
subscribe shortcuts =
    Browser.Events.onKeyDown (decoder shortcuts)



-- INTERNAL


decoder : Shortcuts msg -> Decoder msg
decoder shortcuts =
    Decode.at [ "target", "nodeName" ] Decode.string
        |> Decode.andThen (filterByTag shortcuts)


filterByTag : Shortcuts msg -> String -> Decoder msg
filterByTag shortcuts tag =
    case tag of
        "TEXTAREA" ->
            ignoredTag "TEXTAREA"

        "INPUT" ->
            ignoredTag "INPUT"

        "SELECT" ->
            ignoredTag "SELECT"

        _ ->
            field "key" string
                |> Decode.andThen (msgDecoder shortcuts)


msgDecoder : Shortcuts msg -> String -> Decoder msg
msgDecoder shortcuts key =
    let
        shortcut =
            shortcuts
                |> List.filter (\( testKey, _ ) -> key == testKey)
                |> List.head
    in
    case shortcut of
        Just ( _, msg ) ->
            succeed msg

        Nothing ->
            unrecognizedKey key


ignoredTag : String -> Decoder msg
ignoredTag tag =
    fail ("shortcut keys ignored in " ++ tag)


unrecognizedKey : String -> Decoder msg
unrecognizedKey key =
    fail ("'" ++ key ++ "' is not a shortcut")
