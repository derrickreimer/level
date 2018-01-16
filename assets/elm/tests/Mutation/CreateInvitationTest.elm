module Mutation.CreateInvitationTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)
import TestHelpers exposing (roomFixture)
import Data.ValidationError exposing (ValidationError)
import Mutation.CreateInvitation as CreateInvitation
import Json.Decode exposing (decodeString)
import Json.Encode as Encode


query : Test
query =
    describe "query"
        [ describe "Mutation.CreateInvitation.variables"
            [ test "assembles variables from params" <|
                \_ ->
                    let
                        params =
                            { email = "derrick@level.live"
                            }

                        encodedResult =
                            CreateInvitation.variables params

                        expected =
                            Encode.object
                                [ ( "email", Encode.string params.email )
                                ]
                    in
                        Expect.equal expected encodedResult
            ]
        ]


decoders : Test
decoders =
    describe "decoders"
        [ describe "Mutation.CreateInvitation.decoder"
            [ test "handles success response" <|
                \_ ->
                    let
                        json =
                            """
                              {
                                "data": {
                                  "inviteUser": {
                                    "success": true,
                                    "errors": []
                                  }
                                }
                              }
                            """

                        result =
                            decodeString CreateInvitation.decoder json
                    in
                        Expect.equal (Ok CreateInvitation.Success) result
            , test "handles validation error response" <|
                \_ ->
                    let
                        json =
                            """
                              {
                                "data": {
                                  "inviteUser": {
                                    "success": false,
                                    "errors": [{
                                      "attribute": "email",
                                      "message": "has already been invited"
                                    }]
                                  }
                                }
                              }
                            """

                        result =
                            decodeString CreateInvitation.decoder json

                        expected =
                            CreateInvitation.Invalid
                                [ ValidationError "email" "has already been invited"
                                ]
                    in
                        Expect.equal (Ok expected) result
            ]
        ]
