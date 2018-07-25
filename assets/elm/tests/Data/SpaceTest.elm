module Data.SpaceTest exposing (..)

import Expect exposing (Expectation)
import Data.Space as Space
import Test exposing (..)
import Json.Decode exposing (decodeString)
import TestHelpers exposing (success)


{-| Tests for JSON decoders.
-}
decoders : Test
decoders =
    describe "decoders"
        [ describe "Space.decoder"
            [ test "decodes space JSON" <|
                \_ ->
                    let
                        json =
                            """
                            {
                              "id": "9999",
                              "name": "Drip",
                              "slug": "drip",
                              "avatarUrl": "src"
                            }
                            """

                        result =
                            decodeString Space.decoder json

                        expected =
                            { id = "9999"
                            , name = "Drip"
                            , slug = "drip"
                            , avatarUrl = Just "src"
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
                            decodeString Space.decoder json
                    in
                        Expect.equal False (success result)
            ]
        ]
