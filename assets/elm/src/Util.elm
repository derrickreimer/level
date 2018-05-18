module Util exposing (..)

import Date exposing (Date)
import Date.Format
import Json.Decode as Decode exposing (Decoder, string, andThen, succeed, fail)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (defaultOptions, onWithOptions)
import Http


type Lazy a
    = NotLoaded
    | Loaded a


type alias Identifiable a =
    { a | id : String }



-- LIST HELPERS


{-| Gets the last item from a list.

    last [1, 2, 3] == Just 3
    last [] == Nothing

-}
last : List a -> Maybe a
last =
    List.foldl (Just >> always) Nothing


{-| Computes the size of a list.

    size [1,2,3] == 3
    size [] == 0

-}
size : List a -> Int
size =
    List.foldl (\_ t -> t + 1) 0


{-| Prepends an item to a list if there does not exist a list element with
the same id.

    insertUniqueById { id = "1" } [{ id = "1" }] == [{ id = "1" }]
    insertUniqueById { id = "1" } [{ id = "2" }] == [{ id = "1" }, { id = "2" }]

-}
insertUniqueById : Identifiable a -> List (Identifiable a) -> List (Identifiable a)
insertUniqueById item list =
    if memberById item list then
        list
    else
        item :: list


{-| Determines whether an item is in the list with the same id.

    memberById { id = "1" } [{ id = "1" }] == True
    memberById { id = "1" } [{ id = "2" }] == False

-}
memberById : Identifiable a -> List (Identifiable a) -> Bool
memberById item list =
    let
        id =
            item.id
    in
        list
            |> List.filter (\a -> a.id == id)
            |> List.isEmpty
            |> not


{-| Filters out items from list with a given id.

    removeById "1" [{ id = "1" }, { id = "2" }] == [{ id = "2" }]

-}
removeById : String -> List (Identifiable a) -> List (Identifiable a)
removeById id =
    List.filter (\a -> not (a.id == id))



-- CUSTOM DECODERS


{-| Decodes a Date from JSON.

    decodeString dateDecoder "2017-12-28T10:00:00Z"
    -- Ok <Thu Dec 28 2017 10:00:00 GMT>

-}
dateDecoder : Decoder Date
dateDecoder =
    let
        convert : String -> Decoder Date
        convert raw =
            case Date.fromString raw of
                Ok date ->
                    succeed date

                Err error ->
                    fail error
    in
        string |> andThen convert



-- DATE HELPERS


{-| Converts a Time into a human-friendly HH:MM PP time string.

    formatTime (Date ...) == "9:18 pm"

-}
formatTime : Date -> String
formatTime date =
    Date.Format.format "%-l:%M %P" date


{-| Converts a Time into a human-friendly HH:MM time string.

    formatTime (Date ...) == "9:18"

-}
formatTimeWithoutMeridian : Date -> String
formatTimeWithoutMeridian date =
    Date.Format.format "%-l:%M" date


{-| Converts a Time into a human-friendly date and time string.

    formatDateTime (Date ...) == "Dec 26, 2017 at 11:10 am"

-}
formatDateTime : Date -> String
formatDateTime date =
    Date.Format.format "%b %-e, %Y" date ++ " at " ++ formatTime date


{-| Converts a Time into a human-friendly day string.

    formatDateTime (Date ...) == "Wed, December 26, 2017"

-}
formatDay : Date -> String
formatDay date =
    Date.Format.format "%A, %B %-e, %Y" date


{-| Checks to see if two dates are on the same day.
-}
onSameDay : Date -> Date -> Bool
onSameDay d1 d2 =
    Date.year d1
        == Date.year d2
        && Date.month d1
        == Date.month d2
        && Date.day d1
        == Date.day d2



-- CUSTOM HTML EVENTS


onEnter : msg -> Attribute msg
onEnter msg =
    let
        options =
            { defaultOptions | preventDefault = True }

        codeAndShift : Decode.Decoder ( Int, Bool )
        codeAndShift =
            Decode.map2 (\a b -> ( a, b ))
                Html.Events.keyCode
                (Decode.field "shiftKey" Decode.bool)

        isEnter : ( Int, Bool ) -> Decode.Decoder msg
        isEnter ( code, shiftKey ) =
            if code == 13 && shiftKey == False then
                Decode.succeed msg
            else
                Decode.fail "not ENTER"
    in
        onWithOptions "keydown" options (Decode.andThen isEnter codeAndShift)



-- HTTP HELPERS


postWithCsrfToken : String -> String -> Http.Body -> Decode.Decoder a -> Http.Request a
postWithCsrfToken token url body decoder =
    Http.request
        { method = "POST"
        , headers = [ Http.header "X-Csrf-Token" token ]
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }
