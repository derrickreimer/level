module Data.SessionTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)
import TestHelpers exposing (success)
import Json.Decode exposing (decodeString)
import Jwt
import Data.Session as Session


{-| Tests for decoders.
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
        , describe "Session.decodeToken"
            [ test "decodes a well-formed token" <|
                \_ ->
                    let
                        token =
                            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1MTc1MTcxMzYsImlhdCI6MTUxNzUwOTkzNiwibmJmIjoxNTE3NTA5OTM1LCJzdWIiOiIxMTE1Mzg1Mjg5OTQ3MjI4NzYifQ.E6LR7b8f-P7mGrH7MLM5joaGIisqHNCR-FQF11fyEOs"

                        result =
                            Session.decodeToken token

                        expected =
                            { exp = 1517517136
                            , iat = 1517509936
                            , sub = "111538528994722876"
                            }
                    in
                        Expect.equal (Ok expected) result
            , test "fails with a malformed token" <|
                \_ ->
                    let
                        token =
                            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1MTc1MTcxMzYsImlhCI6MTUxzUwOTkzNiwibmjoxNTE3NTA5OTM1LdWIiiIxMTE1Mzg1Mjg5OTQ3MjI4NzYifQ.E6LR7b8f-P7mGrH7MLM5joaGIisqHNCR-FQF11fyEOs"

                        result =
                            Session.decodeToken token
                    in
                        Expect.equal (Err (Jwt.TokenProcessingError "Wrong length")) result
            ]
        ]
