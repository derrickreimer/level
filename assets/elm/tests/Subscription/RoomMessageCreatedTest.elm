module Subscription.RoomMessageCreatedTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)
import TestHelpers exposing (userFixture)
import Subscription.RoomMessageCreated as RoomMessageCreated
import Json.Decode exposing (decodeString)
import Json.Encode as Encode
import Date


query : Test
query =
    describe "query"
        [ describe "Subscription.RoomMessageCreated.variables"
            [ test "assembles variables from params" <|
                \_ ->
                    let
                        params =
                            { user = userFixture
                            }

                        encodedResult =
                            Encode.encode 0 (RoomMessageCreated.variables params)

                        expected =
                            Encode.encode 0 <|
                                Encode.object
                                    [ ( "userId", Encode.string params.user.id )
                                    ]
                    in
                        Expect.equal expected encodedResult
            ]
        ]


decoders : Test
decoders =
    describe "decoders"
        [ describe "Subscription.RoomMessageCreated.decoder"
            [ test "handles success response" <|
                \_ ->
                    let
                        json =
                            """
                              {
                                "data": {
                                  "roomMessageCreated": {
                                    "room": {
                                      "id": "888"
                                    },
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
                                    }
                                  }
                                }
                              }
                            """

                        result =
                            decodeString RoomMessageCreated.decoder json

                        expected =
                            { roomId = "888"
                            , roomMessage =
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
                            }
                    in
                        Expect.equal (Ok expected) result
            ]
        ]
