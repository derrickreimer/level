module Data.UserTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (string)
import Data.User as User
import Test exposing (..)
import Json.Decode exposing (decodeString)
import TestHelpers exposing (success)


{-| Tests for JSON decoders.
-}
decoders : Test
decoders =
    describe "decoders"
        [ describe "User.userDecoder"
            [ test "decodes room JSON" <|
                \_ ->
                    let
                        json =
                            """
                              {
                                "id": "9999",
                                "firstName": "Derrick",
                                "lastName": "Reimer"
                              }
                            """

                        result =
                            decodeString User.userDecoder json

                        expected =
                            { id = "9999"
                            , firstName = "Derrick"
                            , lastName = "Reimer"
                            }
                    in
                        Expect.equal (Ok expected) result
            , test "does not succeed given invalid JSON" <|
                \_ ->
                    let
                        json =
                            """
                              {
                                "id": "9999"
                              }
                            """

                        result =
                            decodeString User.userDecoder json
                    in
                        Expect.equal False (success result)
            ]
        ]


{-| Tests for utility functions.
-}
utils : Test
utils =
    describe "User.displayName"
        [ fuzz2 string string "joins the first and last name" <|
            \firstName lastName ->
                let
                    user =
                        { id = "999"
                        , firstName = firstName
                        , lastName = lastName
                        }
                in
                    Expect.equal (firstName ++ " " ++ lastName) (User.displayName user)
        ]
