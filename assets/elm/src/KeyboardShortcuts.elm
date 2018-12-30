module KeyboardShortcuts exposing (Modifier(..), subscribe)

import Browser.Events
import Json.Decode as Decode exposing (Decoder, bool, fail, field, string, succeed)


type alias Shortcuts msg =
    List ( String, List Modifier, msg )


type alias KeyboardEvent =
    { key : String
    , modifiers : List Modifier
    }


type Modifier
    = Alt
    | Ctrl
    | Shift
    | Meta



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
            eventDecoder
                |> Decode.andThen (msgDecoder shortcuts)


msgDecoder : Shortcuts msg -> KeyboardEvent -> Decoder msg
msgDecoder shortcuts event =
    let
        shortcut =
            shortcuts
                |> List.filter (\( key, modifiers, _ ) -> event.key == key && modifiers == event.modifiers)
                |> List.head
    in
    case shortcut of
        Just ( _, _, msg ) ->
            succeed msg

        Nothing ->
            unrecognizedKey event.key


ignoredTag : String -> Decoder msg
ignoredTag tag =
    fail ("shortcut keys ignored in " ++ tag)


unrecognizedKey : String -> Decoder msg
unrecognizedKey key =
    fail ("'" ++ key ++ "' is not a shortcut")


eventDecoder : Decoder KeyboardEvent
eventDecoder =
    Decode.map2 KeyboardEvent
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
