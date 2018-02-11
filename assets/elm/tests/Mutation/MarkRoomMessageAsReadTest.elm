module Mutation.MarkRoomMessageAsReadTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)
import TestHelpers exposing (roomFixture)
import Mutation.MarkRoomMessageAsRead as MarkRoomMessageAsRead
import Json.Decode exposing (decodeString)
import Json.Encode as Encode


query : Test
query =
    describe "query"
        [ describe "Mutation.MarkRoomMessageAsRead.variables"
            [ test "assembles variables from params" <|
                \_ ->
                    let
                        params =
                            { roomId = "999"
                            , messageId = "888"
                            }

                        encodedResult =
                            MarkRoomMessageAsRead.variables params

                        expected =
                            Encode.object
                                [ ( "roomId", Encode.string params.roomId )
                                , ( "messageId", Encode.string params.messageId )
                                ]
                    in
                        Expect.equal expected encodedResult
            ]
        ]


decoders : Test
decoders =
    describe "decoders"
        [ describe "Mutation.MarkRoomMessageAsRead.decoder"
            [ test "handles success response" <|
                \_ ->
                    let
                        json =
                            """
                              {
                                "data": {
                                  "markRoomMessageAsRead": {
                                    "success": true,
                                    "errors": []
                                  }
                                }
                              }
                            """

                        result =
                            decodeString MarkRoomMessageAsRead.decoder json
                    in
                        Expect.equal (Ok True) result
            , test "handles validation error response" <|
                \_ ->
                    let
                        json =
                            """
                              {
                                "data": {
                                  "markRoomMessageAsRead": {
                                    "success": false,
                                    "errors": []
                                  }
                                }
                              }
                            """

                        result =
                            decodeString MarkRoomMessageAsRead.decoder json
                    in
                        Expect.equal (Ok False) result
            ]
        ]
