module View.HelpersTest exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (string)
import Test exposing (..)
import Time
import View.Helpers


{-| Tests for utility functions.
-}
suite : Test
suite =
    describe "helpers"
        [ describe "View.Helpers.displayName"
            [ fuzz2 string string "joins the first and last name" <|
                \firstName lastName ->
                    let
                        user =
                            { id = "999"
                            , firstName = firstName
                            , lastName = lastName
                            }
                    in
                    Expect.equal (firstName ++ " " ++ lastName) (View.Helpers.displayName user)
            ]
        ]
