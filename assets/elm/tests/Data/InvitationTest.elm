module Data.InvitationTest exposing (..)

import Expect exposing (Expectation)
import Data.Invitation as Invitation
import Test exposing (..)
import Json.Decode exposing (decodeString)
import TestHelpers exposing (success)
import Date


{-| Tests for JSON decoders.
-}
decoders : Test
decoders =
    describe "decoders"
        [ describe "Invitation.invitationConnectionDecoder"
            [ test "decodes invitation JSON" <|
                \_ ->
                    let
                        json =
                            """
                              {
                                "edges": [{
                                  "node": {
                                    "id": "123",
                                    "email": "d@level.space",
                                    "insertedAt": "2017-12-29T01:45:32Z"
                                  }
                                }],
                                "pageInfo": {
                                  "hasPreviousPage": false,
                                  "hasNextPage": false,
                                  "startCursor": "XXX",
                                  "endCursor": "XXX"
                                },
                                "totalCount": 1
                              }
                            """

                        result =
                            decodeString Invitation.invitationConnectionDecoder json

                        expected =
                            { edges =
                                [ { node =
                                        { id = "123"
                                        , email = "d@level.space"
                                        , insertedAt = Date.fromTime 1514511932000
                                        }
                                  }
                                ]
                            , pageInfo =
                                { hasPreviousPage = False
                                , hasNextPage = False
                                , startCursor = Just "XXX"
                                , endCursor = Just "XXX"
                                }
                            , totalCount = 1
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
                            decodeString Invitation.invitationConnectionDecoder json
                    in
                        Expect.equal False (success result)
            ]
        ]
