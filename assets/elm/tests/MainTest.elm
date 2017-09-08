module MainTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, list, int, string)
import Main
import Test exposing (..)


utils : Test
utils =
    describe "Main.displayName"
        [ fuzz2 string string "joins the first and last name" <|
            \firstName lastName ->
                let
                    user =
                        { firstName = firstName
                        , lastName = lastName
                        }
                in
                    Expect.equal (firstName ++ " " ++ lastName) (Main.displayName user)
        ]
