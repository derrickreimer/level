module UtilTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (string)
import Test exposing (..)
import Util


{-| Tests for utility functions.
-}
utils : Test
utils =
    describe "Util.displayName"
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
