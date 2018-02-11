module Query.RoomSettingsTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)
import Data.Room
import Query.RoomSettings as RoomSettings
import Json.Decode exposing (decodeString)
import Date


decoders : Test
decoders =
    describe "decoders"
        [ describe "Query.RoomSettings.decoder"
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
                                    "subscriberPolicy": "PUBLIC",
                                    "lastMessage": {
                                      "id": "8888"
                                    },
                                    "users": {
                                      "pageInfo": {
                                        "hasPreviousPage": false,
                                        "hasNextPage": false,
                                        "startCursor": "xxx",
                                        "endCursor": "xxx"
                                      },
                                      "edges": [{
                                        "node": {
                                          "id": "9999",
                                          "firstName": "Derrick",
                                          "lastName": "Reimer"
                                        },
                                        "cursor": "xxx"
                                      }]
                                    }
                                  }
                                }
                              }
                            }
                            """

                        result =
                            decodeString RoomSettings.decoder json

                        expected =
                            { room =
                                { id = "9999"
                                , name = "Everyone"
                                , description = "All the things"
                                , subscriberPolicy = Data.Room.Public
                                , lastMessageId = Just "8888"
                                }
                            , users =
                                { edges =
                                    [ { node =
                                            { id = "9999"
                                            , firstName = "Derrick"
                                            , lastName = "Reimer"
                                            }
                                      }
                                    ]
                                , pageInfo =
                                    { hasPreviousPage = False
                                    , hasNextPage = False
                                    , startCursor = Just "xxx"
                                    , endCursor = Just "xxx"
                                    }
                                }
                            }
                    in
                        Expect.equal (Ok (RoomSettings.Found expected)) result
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
                            decodeString RoomSettings.decoder json
                    in
                        Expect.equal (Ok RoomSettings.NotFound) result
            ]
        ]
