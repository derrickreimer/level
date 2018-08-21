module Vendor.Keys exposing
    ( Modifier(..), KeyCode, KeyboardEvent, Listener
    , enter, esc, tab
    , defaultOptions, preventDefault
    , onKeydown, onKeypress, onKeyup
    )

{-| Advanced keyboard event listener functions.


# Definitions

@docs Modifier, KeyCode, KeyboardEvent, Listener


# Key Code Helpers

@docs enter, esc, tab


# Option Helpers

@docs defaultOptions, preventDefault


# Events

@docs onKeydown, onKeypress, onKeyup

-}

import Html exposing (Attribute)
import Html.Events exposing (Options, onWithOptions)
import Json.Decode as Decode exposing (Decoder, bool, field, int)
import List
import Tuple


{-| The possible modifier keys on keyboard events.
-}
type Modifier
    = Alt
    | Ctrl
    | Shift
    | Meta


{-| An ASCII character code.
-}
type alias KeyCode =
    Int


{-| A JavaScript keyboard event.
-}
type alias KeyboardEvent =
    { keyCode : KeyCode
    , modifiers : List Modifier
    , repeat : Bool
    }


{-| An event listener definition.
-}
type alias Listener msg =
    ( List Modifier, KeyCode, KeyboardEvent -> msg )



-- KEYCODE HELPERS


{-| The code for the `tab` key.
-}
tab : KeyCode
tab =
    9


{-| The code for the `enter` key.
-}
enter : KeyCode
enter =
    13


{-| The code for the `esc` key.
-}
esc : KeyCode
esc =
    27



-- OPTION HELPERS


{-| The default event options.

See [`Html.Events`](events).

[events]: http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html-Events#Options

-}
defaultOptions : Options
defaultOptions =
    Html.Events.defaultOptions


{-| Prevent the default behavior when the event fires.
-}
preventDefault : Options
preventDefault =
    { defaultOptions | preventDefault = True }



-- EVENTS


{-| Capture <keydown> events on inputs and text areas and match against
one or more different sets of listener criteria.

Suppose you want to listen for both the `esc` key and the `meta + enter` key combinations
and prevent the default behavior. You would define your event listener like this:

    import Vendor.Keys as Keys exposing (KeyboardEvent, Modifier(..), enter, esc, onKeydown, preventDefault)

    type Msg
        = Escaped KeyboardEvent
        | Submitted KeyboardEvent

    view : Html Msg
    view =
        textarea
            [ onKeydown preventDefault
                [ ( [ Meta ], enter, Submitted )
                , ( [], esc, Escaped )
                ]
            ]

The first argument is [`Html.Events` options](options) and the second argument is
an array of three-part tuples containing:

  - the required modifier keys (shift, alt, control, or meta),
  - the key code, and
  - the message constructor

[keydown]: https://developer.mozilla.org/en-US/docs/Web/Events/keydown
[options]: http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html-Events#Options

-}
onKeydown : Options -> List (Listener msg) -> Attribute msg
onKeydown =
    onKeyboardEvent "down"


{-| Capture <keypress> events on inputs and text areas and match against
one or more different sets of listener criteria.

See [`onKeydown`](#onKeydown) for more information.

[keypress]: https://developer.mozilla.org/en-US/docs/Web/Events/keypress

-}
onKeypress : Options -> List (Listener msg) -> Attribute msg
onKeypress =
    onKeyboardEvent "press"


{-| Capture <keyup> events on inputs and text areas and match against
one or more different sets of listener criteria.

See [`onKeydown`](#onKeydown) for more information.

[keyup]: https://developer.mozilla.org/en-US/docs/Web/Events/keyup

-}
onKeyup : Options -> List (Listener msg) -> Attribute msg
onKeyup =
    onKeyboardEvent "up"



-- PRIVATE FUNCTIONS


onKeyboardEvent : String -> Options -> List (Listener msg) -> Attribute msg
onKeyboardEvent action options listeners =
    eventDecoder
        |> Decode.andThen (checkListeners listeners)
        |> onWithOptions ("key" ++ action) options


eventDecoder : Decoder KeyboardEvent
eventDecoder =
    Decode.map3 KeyboardEvent
        (field "keyCode" int)
        modifierDecoder
        (field "repeat" bool)


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


checkListeners : List (Listener msg) -> KeyboardEvent -> Decoder msg
checkListeners listeners event =
    case listeners of
        [] ->
            Decode.fail "no match"

        [ ( modifiers, keyCode, toMsg ) ] ->
            if isMatch modifiers keyCode event then
                Decode.succeed (toMsg event)

            else
                Decode.fail "no match"

        ( modifiers, keyCode, toMsg ) :: tl ->
            if isMatch modifiers keyCode event then
                Decode.succeed (toMsg event)

            else
                checkListeners tl event


isMatch : List Modifier -> KeyCode -> KeyboardEvent -> Bool
isMatch modifiers keyCode event =
    keyCode == event.keyCode && hasSameMembers modifiers event.modifiers


hasSameMembers : List a -> List a -> Bool
hasSameMembers a b =
    let
        subset a b =
            List.all (\i -> List.member i a) b
    in
    subset a b && subset b a
