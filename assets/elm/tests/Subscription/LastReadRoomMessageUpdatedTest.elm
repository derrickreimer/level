module Subscription.LastReadRoomMessageUpdatedTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)
import TestHelpers exposing (userFixture)
import Subscription.LastReadRoomMessageUpdated as LastReadRoomMessageUpdated
import Json.Decode exposing (decodeString)
import Json.Encode as Encode


query : Test
query =
    describe "query"
        [ describe "Subscription.LastReadRoomMessageUpdated.variables"
            [ test "assembles variables from params" <|
                \_ ->
                    let
                        params =
                            { user = userFixture
                            }

                        encodedResult =
                            Encode.encode 0 (LastReadRoomMessageUpdated.variables params)

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
        [ describe "Subscription.LastReadRoomMessageUpdated.decoder"
            [ test "handles success response" <|
                \_ ->
                    let
                        json =
                            """
                              {
                                "data": {
                                  "lastReadRoomMessageUpdated": {
                                    "roomSubscription": {
                                      "room": {
                                        "id": "888"
                                      },
                                      "lastReadMessage": {
                                        "id": "999"
                                      }
                                    }
                                  }
                                }
                              }
                            """

                        result =
                            decodeString LastReadRoomMessageUpdated.decoder json

                        expected =
                            { roomId = "888"
                            , messageId = "999"
                            }
                    in
                        Expect.equal (Ok expected) result
            ]
        ]
