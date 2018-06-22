module Util exposing (..)

import Date exposing (Date)
import Date.Format
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder, string, andThen, succeed, fail)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (defaultOptions, on, onWithOptions, keyCode)
import Http
import Time


type Lazy a
    = NotLoaded
    | Loaded a


type alias Identifiable a =
    { a | id : String }


type alias Nameable a =
    { a | firstName : String, lastName : String }



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


{-| Converts a date into a human-friendly HH:MM PP time string.

    formatTime (Date ...) == "9:18 pm"

-}
formatTime : Date -> String
formatTime date =
    Date.Format.format "%-l:%M %P" date


{-| Converts a date into a human-friendly HH:MM time string.

    formatTime (Date ...) == "9:18"

-}
formatTimeWithoutMeridian : Date -> String
formatTimeWithoutMeridian date =
    Date.Format.format "%-l:%M" date


{-| Converts a date into a human-friendly date and time string.

    formatDateTime False (Date ...) == "Dec 26 at 11:10 am"
    formatDateTime True (Date ...) == "Dec 26, 2018 at 11:10 am"

-}
formatDateTime : Bool -> Date -> String
formatDateTime withYear date =
    let
        dateString =
            if withYear then
                "%b %-e, %Y"
            else
                "%b %-e"
    in
        Date.Format.format dateString date ++ " at " ++ formatTime date


{-| Converts a date into a human-friendly day string.

    formatDay (Date ...) == "Wed, December 26, 2017"

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


{-| Checks to see if two days are further than one year apart.
-}
isOverOneYearAgo : Date -> Date -> Bool
isOverOneYearAgo now pastDate =
    (Date.toTime now) - (Date.toTime pastDate) > (Time.hour * 24 * 365)


{-| Formats the given date intelligently, relative to the current time.

    smartFormatDate now someTimeToday == "Today at 10:01am"
    smartFormatDate now daysAgo == "May 15 at 5:45pm"
    smartFormatDate now overOneYearAgo == "May 10, 2017 at 4:45pm"

-}
smartFormatDate : Date -> Date -> String
smartFormatDate now date =
    if onSameDay now date then
        "Today at " ++ (formatTime date)
    else if isOverOneYearAgo now date then
        formatDateTime True date
    else
        formatDateTime False date



-- CUSTOM HTML EVENTS


onEnter : Bool -> msg -> Attribute msg
onEnter shiftRequired msg =
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
            if code == 13 && shiftKey == shiftRequired then
                Decode.succeed msg
            else
                Decode.fail "not ENTER"
    in
        onWithOptions "keydown" options (Decode.andThen isEnter codeAndShift)


onEnterOrEsc : msg -> msg -> Attribute msg
onEnterOrEsc enterMsg escMsg =
    let
        isEnterOrEsc : Int -> Decode.Decoder msg
        isEnterOrEsc code =
            case code of
                13 ->
                    Decode.succeed enterMsg

                27 ->
                    Decode.succeed escMsg

                _ ->
                    Decode.fail "not ENTER or ESC"
    in
        on "keydown" (Decode.andThen isEnterOrEsc keyCode)



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



-- MISC


{-| Generate the display name for a given user.

    displayName { firstName = "Derrick", lastName = "Reimer" } == "Derrick Reimer"

-}
displayName : Nameable a -> String
displayName nameable =
    nameable.firstName ++ " " ++ nameable.lastName


{-| Inject a raw string of HTML into a div.
-}
injectHtml : String -> Html msg
injectHtml rawHtml =
    div [ property "innerHTML" <| Encode.string rawHtml ] []
