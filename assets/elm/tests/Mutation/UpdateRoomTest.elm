module Mutation.UpdateRoomTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)
import TestHelpers exposing (roomFixture)
import Data.Room exposing (subscriberPolicyEncoder)
import Data.ValidationError exposing (ValidationError)
import Mutation.UpdateRoom as UpdateRoom
import Json.Decode exposing (decodeString)
import Json.Encode as Encode


query : Test
query =
    describe "query"
        [ describe "Mutation.UpdateRoom.variables"
            [ test "assembles variables from params" <|
                \_ ->
                    let
                        params =
                            { id = "1234567"
                            , name = "Development"
                            , description = "A place for devs to hang out."
                            , subscriberPolicy = Data.Room.Public
                            }

                        encodedResult =
                            UpdateRoom.variables params

                        expected =
                            Encode.object
                                [ ( "id", Encode.string params.id )
                                , ( "name", Encode.string params.name )
                                , ( "description", Encode.string params.description )
                                , ( "subscriberPolicy", subscriberPolicyEncoder params.subscriberPolicy )
                                ]
                    in
                        Expect.equal expected encodedResult
            ]
        ]


decoders : Test
decoders =
    describe "decoders"
        [ describe "Mutation.UpdateRoom.decoder"
            [ test "handles success response" <|
                \_ ->
                    let
                        json =
                            """
                              {
                                "data": {
                                  "updateRoom": {
                                    "room": {
                                      "id": "9999",
                                      "name": "Development",
                                      "description": "A place for devs to hang out.",
                                      "subscriberPolicy": "PUBLIC"
                                    },
                                    "success": true,
                                    "errors": []
                                  }
                                }
                              }
                            """

                        result =
                            decodeString UpdateRoom.decoder json

                        expected =
                            UpdateRoom.Success
                                { id = "9999"
                                , name = "Development"
                                , description = "A place for devs to hang out."
                                , subscriberPolicy = Data.Room.Public
                                }
                    in
                        Expect.equal (Ok expected) result
            , test "handles validation error response" <|
                \_ ->
                    let
                        json =
                            """
                              {
                                "data": {
                                  "updateRoom": {
                                    "room": {
                                      "id": "9999",
                                      "name": "Development",
                                      "description": "A place for devs to hang out.",
                                      "subscriberPolicy": "PUBLIC"
                                    },
                                    "success": false,
                                    "errors": [{
                                      "attribute": "name",
                                      "message": "is already taken"
                                    }]
                                  }
                                }
                              }
                            """

                        result =
                            decodeString UpdateRoom.decoder json

                        expected =
                            UpdateRoom.Invalid
                                [ ValidationError "name" "is already taken"
                                ]
                    in
                        Expect.equal (Ok expected) result
            ]
        ]
