module Mutation.CreateRoomMessageTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)
import TestHelpers exposing (roomFixture)
import Mutation.CreateRoomMessage as CreateRoomMessage
import Json.Decode exposing (decodeString)
import Json.Encode
import Date


query : Test
query =
    describe "query"
        [ describe "Mutation.CreateRoomMessage.variables"
            [ test "assembles variables from params" <|
                \_ ->
                    let
                        params =
                            { room = roomFixture
                            , body = "Hello world"
                            }

                        encodedResult =
                            Json.Encode.encode 0 (CreateRoomMessage.variables params)

                        expected =
                            "{\"roomId\":\"" ++ params.room.id ++ "\",\"body\":\"" ++ params.body ++ "\"}"
                    in
                        Expect.equal expected encodedResult
            ]
        ]


decoders : Test
decoders =
    describe "decoders"
        [ describe "Mutation.CreateRoomMessage.decoder"
            [ test "handles success response" <|
                \_ ->
                    let
                        json =
                            """
                              {
                                "data": {
                                  "createRoomMessage": {
                                    "roomMessage": {
                                      "id": "9999",
                                      "body": "Hello world",
                                      "user": {
                                        "id": "8888",
                                        "firstName": "Derrick",
                                        "lastName": "Reimer"
                                      },
                                      "insertedAt": "2017-12-29T01:45:32Z",
                                      "insertedAtTs": 1514511932000
                                    },
                                    "success": true,
                                    "errors": []
                                  }
                                }
                              }
                            """

                        result =
                            decodeString CreateRoomMessage.decoder json

                        expected =
                            { id = "9999"
                            , body = "Hello world"
                            , insertedAt = Date.fromTime 1514511932000
                            , insertedAtTs = 1514511932000.0
                            , user =
                                { id = "8888"
                                , firstName = "Derrick"
                                , lastName = "Reimer"
                                }
                            }
                    in
                        Expect.equal (Ok expected) result
            ]
        ]
