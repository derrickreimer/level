module Data.RoomTest exposing (..)

import Expect exposing (Expectation)
import Data.Room as Room
import Test exposing (..)
import Json.Decode exposing (decodeString)
import TestHelpers exposing (success)


{-| Tests for JSON decoders.
-}
decoders : Test
decoders =
    describe "decoders"
        [ describe "Room.roomDecoder"
            [ test "decodes room JSON" <|
                \_ ->
                    let
                        json =
                            """
                            {
                                "id": "9999",
                                "name": "Drip"
                            }
                            """

                        result =
                            decodeString Room.roomDecoder json

                        expected =
                            { id = "9999"
                            , name = "Drip"
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
                            decodeString Room.roomDecoder json
                    in
                        Expect.equal False (success result)
            ]
        , describe "Room.roomSubscriptionConnectionDecoder"
            [ test "decodes connection JSON" <|
                \_ ->
                    let
                        json =
                            """
                            {
                                "edges": [{
                                    "node": {
                                        "room": {
                                            "id": "123",
                                            "name": "Everyone"
                                        }
                                    }
                                }]
                            }
                            """

                        result =
                            decodeString Room.roomSubscriptionConnectionDecoder json

                        expected =
                            { edges =
                                [ { node =
                                        { room =
                                            { id = "123"
                                            , name = "Everyone"
                                            }
                                        }
                                  }
                                ]
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
                            decodeString Room.roomSubscriptionConnectionDecoder json
                    in
                        Expect.equal False (success result)
            ]
        ]
