module SpaceTest exposing (decoders)

import Space
import Expect exposing (Expectation)
import Json.Decode as Decode exposing (decodeString)
import Test exposing (..)
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
                              "avatarUrl": "src",
                              "fetchedAt": 0
                            }
                            """

                        expected =
                            { id = "9999"
                            , name = "Drip"
                            , slug = "drip"
                            , avatarUrl = Just "src"
                            , fetchedAt = 0
                            }
                    in
                    case decodeString Space.decoder json of
                        Ok value ->
                            Expect.equal expected (Space.getCachedData value)

                        Err err ->
                            Expect.fail (Decode.errorToString err)
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
