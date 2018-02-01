module Data.SessionTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)
import TestHelpers exposing (success)
import Json.Decode exposing (decodeString)
import Data.Session as Session


{-| Tests for JSON decoders.
-}
decoders : Test
decoders =
    describe "decoders"
        [ describe "Session.payloadDecoder"
            [ test "decodes well-formed JWT payloads" <|
                \_ ->
                    let
                        json =
                            """
                              {
                                "exp": 1517515691,
                                "iat": 1517508491,
                                "nbf": 1517508490,
                                "sub": "111538528994722880"
                              }
                            """

                        result =
                            decodeString Session.payloadDecoder json

                        expected =
                            { exp = 1517515691
                            , iat = 1517508491
                            , sub = "111538528994722880"
                            }
                    in
                        Expect.equal (Ok expected) result
            , test "does not succeed given invalid JSON" <|
                \_ ->
                    let
                        json =
                            """
                              {
                                "foo": "bar"
                              }
                            """

                        result =
                            decodeString Session.payloadDecoder json
                    in
                        Expect.equal False (success result)
            ]
        ]
