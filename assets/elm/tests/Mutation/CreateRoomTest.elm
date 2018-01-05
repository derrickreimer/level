module Mutation.CreateRoomTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)
import TestHelpers exposing (roomFixture)
import Data.Room exposing (subscriberPolicyEncoder)
import Data.ValidationError exposing (ValidationError)
import Mutation.CreateRoom as CreateRoom
import Json.Decode exposing (decodeString)
import Json.Encode as Encode


query : Test
query =
    describe "query"
        [ describe "Mutation.CreateRoom.variables"
            [ test "assembles variables from params" <|
                \_ ->
                    let
                        params =
                            { name = "Development"
                            , description = "A place for devs to hang out."
                            , subscriberPolicy = Data.Room.Public
                            }

                        encodedResult =
                            CreateRoom.variables params

                        expected =
                            Encode.object
                                [ ( "name", Encode.string params.name )
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
        [ describe "Mutation.CreateRoom.decoder"
            [ test "handles success response" <|
                \_ ->
                    let
                        json =
                            """
                              {
                                "data": {
                                  "createRoom": {
                                    "roomSubscription": {
                                      "room": {
                                        "id": "9999",
                                        "name": "Development",
                                        "description": "A place for devs to hang out.",
                                        "subscriberPolicy": "PUBLIC"
                                      }
                                    },
                                    "success": true,
                                    "errors": []
                                  }
                                }
                              }
                            """

                        result =
                            decodeString CreateRoom.decoder json

                        expected =
                            CreateRoom.Success
                                { room =
                                    { id = "9999"
                                    , name = "Development"
                                    , description = "A place for devs to hang out."
                                    , subscriberPolicy = Data.Room.Public
                                    }
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
                                  "createRoom": {
                                    "roomSubscription": null,
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
                            decodeString CreateRoom.decoder json

                        expected =
                            CreateRoom.Invalid
                                [ ValidationError "name" "is already taken"
                                ]
                    in
                        Expect.equal (Ok expected) result
            ]
        ]
