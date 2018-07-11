module ViewHelpersTest exposing (..)

import Date exposing (Date)
import Time
import Expect exposing (Expectation)
import Fuzz exposing (string)
import Test exposing (..)
import ViewHelpers


{-| An arbitrary day considered to be "now".
-}
now : Date
now =
    case Date.fromString "1988-09-28 05:00:00" of
        Ok date ->
            date

        _ ->
            Debug.crash "Unable to parse date"


{-| Tests for utility functions.
-}
suite : Test
suite =
    describe "helpers"
        [ describe "ViewHelpers.displayName"
            [ fuzz2 string string "joins the first and last name" <|
                \firstName lastName ->
                    let
                        user =
                            { id = "999"
                            , firstName = firstName
                            , lastName = lastName
                            }
                    in
                        Expect.equal (firstName ++ " " ++ lastName) (ViewHelpers.displayName user)
            ]
        , describe "ViewHelpers.smartFormatDate"
            [ test "formats dates on the same day" <|
                \_ ->
                    let
                        minutesAgo =
                            (Date.toTime now)
                                - (Time.minute * 3)
                                |> Date.fromTime
                    in
                        Expect.equal "Today at 4:57 am" (ViewHelpers.smartFormatDate now minutesAgo)
            , test "formats dates within a few days" <|
                \_ ->
                    let
                        daysAgo =
                            (Date.toTime now)
                                - (Time.hour * 48)
                                |> Date.fromTime
                    in
                        Expect.equal "Sep 26 at 5:00 am" (ViewHelpers.smartFormatDate now daysAgo)
            , test "formats dates over a year ago" <|
                \_ ->
                    let
                        overOneYearAgo =
                            (Date.toTime now)
                                - (Time.hour * 24 * 367)
                                |> Date.fromTime
                    in
                        Expect.equal "Sep 27, 1987 at 5:00 am" (ViewHelpers.smartFormatDate now overOneYearAgo)
            ]
        ]
