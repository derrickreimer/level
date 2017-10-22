module Query.RoomTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)
import Query.Room as Room
import Json.Decode exposing (decodeString)


decoders : Test
decoders =
    describe "decoders"
        [ describe "Query.Room.okDecoder"
            [ test "parses valid response" <|
                \_ ->
                    let
                        json =
                            """
                            {
                                "room": {
                                    "id": "9999",
                                    "name": "Everyone",
                                    "description": "All the things"
                                }
                            }
                            """

                        result =
                            decodeString Room.okDecoder json

                        expected =
                            { room =
                                { id = "9999"
                                , name = "Everyone"
                                , description = "All the things"
                                }
                            }
                    in
                        Expect.equal (Ok (Room.Ok expected)) result
            ]
        , describe "Query.Room.notFoundDecoder"
            [ test "parses not found response" <|
                \_ ->
                    let
                        json =
                            """
                            {
                                "room": null
                            }
                            """

                        result =
                            decodeString Room.notFoundDecoder json
                    in
                        Expect.equal (Ok Room.NotFound) result
            ]
        ]
