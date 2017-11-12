module Query.RoomTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)
import Query.Room as Room
import Json.Decode exposing (decodeString)


decoders : Test
decoders =
    describe "decoders"
        [ describe "Query.Room.decoder"
            [ test "handles response where room is found" <|
                \_ ->
                    let
                        json =
                            """
                            {
                              "data": {
                                "viewer": {
                                  "room": {
                                    "id": "9999",
                                    "name": "Everyone",
                                    "description": "All the things",
                                    "messages": {
                                      "edges": [{
                                        "node": {
                                          "id": "8888",
                                          "body": "Hello world",
                                          "insertedAtTs": 1510444158581,
                                          "user": {
                                            "id": "7777",
                                            "firstName": "Derrick",
                                            "lastName": "Reimer"
                                          }
                                        }
                                      }]
                                    }
                                  }
                                }
                              }
                            }
                            """

                        result =
                            decodeString Room.decoder json

                        expected =
                            { room =
                                { id = "9999"
                                , name = "Everyone"
                                , description = "All the things"
                                }
                            , messages =
                                { edges =
                                    [ { node =
                                            { id = "8888"
                                            , body = "Hello world"
                                            , insertedAt = 1510444158581
                                            , user =
                                                { id = "7777"
                                                , firstName = "Derrick"
                                                , lastName = "Reimer"
                                                }
                                            }
                                      }
                                    ]
                                }
                            }
                    in
                        Expect.equal (Ok (Room.Found expected)) result
            , test "handles response when room is not found" <|
                \_ ->
                    let
                        json =
                            """
                            {
                              "data": {
                                "viewer": {
                                  "room": null
                                }
                              }
                            }
                            """

                        result =
                            decodeString Room.decoder json
                    in
                        Expect.equal (Ok Room.NotFound) result
            ]
        ]
