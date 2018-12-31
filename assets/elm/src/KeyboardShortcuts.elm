module KeyboardShortcuts exposing (Event, Modifier(..), subscribe)

import Browser.Events
import Json.Decode as Decode exposing (Decoder, bool, fail, field, string, succeed)


type alias Shortcuts msg =
    List ( String, List Modifier, msg )


type alias Event =
    { key : String
    , modifiers : List Modifier
    }


type Modifier
    = Alt
    | Ctrl
    | Shift
    | Meta



-- API


subscribe : (Event -> msg) -> Sub msg
subscribe toMsg =
    Browser.Events.onKeyDown (decoder toMsg)



-- INTERNAL


decoder : (Event -> msg) -> Decoder msg
decoder toMsg =
    Decode.at [ "target", "nodeName" ] Decode.string
        |> Decode.andThen (filterByTag toMsg)


filterByTag : (Event -> msg) -> String -> Decoder msg
filterByTag toMsg tag =
    case tag of
        "TEXTAREA" ->
            ignoredTag "TEXTAREA"

        "INPUT" ->
            ignoredTag "INPUT"

        "SELECT" ->
            ignoredTag "SELECT"

        _ ->
            Decode.map toMsg eventDecoder


ignoredTag : String -> Decoder msg
ignoredTag tag =
    fail ("shortcut keys ignored in " ++ tag)


eventDecoder : Decoder Event
eventDecoder =
    Decode.map2 Event
        (field "key" string)
        modifierDecoder


modifierDecoder : Decoder (List Modifier)
modifierDecoder =
    Decode.map4 mapModifiers
        (field "altKey" bool)
        (field "ctrlKey" bool)
        (field "shiftKey" bool)
        (field "metaKey" bool)


mapModifiers : Bool -> Bool -> Bool -> Bool -> List Modifier
mapModifiers altKey ctrlKey shiftKey metaKey =
    [ ( Alt, altKey ), ( Ctrl, ctrlKey ), ( Shift, shiftKey ), ( Meta, metaKey ) ]
        |> List.filter Tuple.second
        |> List.map Tuple.first
