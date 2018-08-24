module GroupMembershipTest exposing (decoders)

import Expect exposing (Expectation)
import Fuzz exposing (string)
import GroupMembership exposing (GroupMembershipState(..), stateDecoder)
import Json.Decode as Decode exposing (decodeString, field)
import Test exposing (..)
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
                                |> Result.mapError Decode.errorToString
                    in
                    Expect.equal (Err "Problem with the value at json.state:\n\n    \"INVALID\"\n\nMembership state not valid") result
            ]
        ]
