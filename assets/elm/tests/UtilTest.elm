module UtilTest exposing (..)

import Date exposing (Date)
import Time
import Expect exposing (Expectation)
import Fuzz exposing (string)
import Test exposing (..)
import Util


{-| An arbitrary day considered to be "now" (Sept 28 1988 at 5:00:00).
-}
now : Date
now =
    Date.fromTime 591444000000


{-| Tests for utility functions.
-}
utils : Test
utils =
    describe "utils"
        [ describe "Util.displayName"
            [ fuzz2 string string "joins the first and last name" <|
                \firstName lastName ->
                    let
                        user =
                            { id = "999"
                            , firstName = firstName
                            , lastName = lastName
                            }
                    in
                        Expect.equal (firstName ++ " " ++ lastName) (Util.displayName user)
            ]
        , describe "Util.smartFormatDate"
            [ test "formats dates on the same day" <|
                \_ ->
                    let
                        minutesAgo =
                            (Date.toTime now)
                                - (Time.minute * 3)
                                |> Date.fromTime
                    in
                        Expect.equal "Today at 4:57 am" (Util.smartFormatDate now minutesAgo)
            , test "formats dates within a few days" <|
                \_ ->
                    let
                        daysAgo =
                            (Date.toTime now)
                                - (Time.hour * 48)
                                |> Date.fromTime
                    in
                        Expect.equal "Sep 26 at 5:00 am" (Util.smartFormatDate now daysAgo)
            , test "formats dates over a year ago" <|
                \_ ->
                    let
                        overOneYearAgo =
                            (Date.toTime now)
                                - (Time.hour * 24 * 367)
                                |> Date.fromTime
                    in
                        Expect.equal "Sep 27, 1987 at 5:00 am" (Util.smartFormatDate now overOneYearAgo)
            ]
        ]
