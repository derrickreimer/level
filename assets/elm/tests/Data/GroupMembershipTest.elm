module Data.GroupMembershipTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (string)
import Data.GroupMembership as GroupMembership exposing (GroupMembershipState(..), stateDecoder)
import Test exposing (..)
import Json.Decode as Decode exposing (decodeString, field)
import TestHelpers exposing (success)


{-| Tests for JSON decoders.
-}
decoders : Test
decoders =
    describe "decoders"
        [ describe "GroupMembership.stateDecoder"
            [ test "decodes subscribed state" <|
                \_ ->
                    let
                        json =
                            """
                            {"state": "SUBSCRIBED"}
                            """

                        result =
                            decodeString (field "state" stateDecoder) json
                    in
                        Expect.equal (Ok Subscribed) result
            , test "decodes not subscribed state" <|
                \_ ->
                    let
                        json =
                            """
                            {"state": "NOT_SUBSCRIBED"}
                            """

                        result =
                            decodeString (field "state" stateDecoder) json
                    in
                        Expect.equal (Ok NotSubscribed) result
            , test "errors out with invalid states" <|
                \_ ->
                    let
                        json =
                            """
                            {"state": "INVALID"}
                            """

                        result =
                            decodeString (field "state" stateDecoder) json
                    in
                        Expect.equal (Err "I ran into a `fail` decoder at _.state: Membership state not valid") result
            ]
        ]
