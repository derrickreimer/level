module KeyboardEvents exposing (Modifier(..), onKeyDown, enter, esc, preventDefault)

import Html exposing (Attribute)
import Html.Events exposing (Options, onWithOptions, defaultOptions)
import Json.Decode as Decode exposing (Decoder, field, int, bool)
import List
import Tuple


type alias KeyCode =
    Int


type Modifier
    = Unmodified
    | Alt
    | Ctrl
    | Shift
    | Meta


type alias Event =
    { keyCode : KeyCode
    , modifiers : List Modifier
    }


type alias Listener a =
    { modifier : Modifier
    , key : KeyCode
    , msg : a
    }



-- KEYCODE HELPERS


enter : KeyCode
enter =
    13


esc : KeyCode
esc =
    27



-- OPTION HELPERS


preventDefault : Options
preventDefault =
    { defaultOptions | preventDefault = True }



-- EVENTS


onKeyDown : Options -> List ( Modifier, KeyCode, msg ) -> Attribute msg
onKeyDown options argList =
    let
        listeners =
            List.map listener argList
    in
        eventDecoder
            |> Decode.andThen (checkListeners listeners)
            |> onWithOptions "keydown" options


listener : ( Modifier, KeyCode, msg ) -> Listener msg
listener ( modifier, keyCode, msg ) =
    Listener modifier keyCode msg



-- DECODERS


eventDecoder : Decoder Event
eventDecoder =
    Decode.map2 Event
        (field "keyCode" int)
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


checkListeners : List (Listener msg) -> Event -> Decode.Decoder msg
checkListeners list event =
    case list of
        [] ->
            Decode.fail "no match"

        [ hd ] ->
            if isMatch hd event then
                Decode.succeed hd.msg
            else
                Decode.fail "no match"

        hd :: tl ->
            if isMatch hd event then
                Decode.succeed hd.msg
            else
                checkListeners tl event


isMatch : Listener msg -> Event -> Bool
isMatch { key, modifier } event =
    key == event.keyCode && (modifierMatches modifier event)


modifierMatches : Modifier -> Event -> Bool
modifierMatches modifier { modifiers } =
    case modifier of
        Unmodified ->
            List.isEmpty modifiers

        _ ->
            [ modifier ] == modifiers
