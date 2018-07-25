module Subscription.SpaceSubscription
    exposing
        ( subscribe
        , unsubscribe
        , spaceUpdatedDecoder
        , spaceUserUpdatedDecoder
        )

import Json.Decode as Decode
import Json.Encode as Encode
import Data.Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import GraphQL exposing (Document)
import Socket


-- SOCKETS


subscribe : String -> Cmd msg
subscribe spaceId =
    Socket.send (clientId spaceId) document (variables spaceId)


unsubscribe : String -> Cmd msg
unsubscribe spaceId =
    Socket.cancel (clientId spaceId)



-- DECODERS


spaceUpdatedDecoder : Decode.Decoder Space
spaceUpdatedDecoder =
    let
        payloadDecoder typename =
            if typename == "SpaceUpdatedPayload" then
                Decode.field "space" Data.Space.decoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder


spaceUserUpdatedDecoder : Decode.Decoder SpaceUser
spaceUserUpdatedDecoder =
    let
        payloadDecoder typename =
            if typename == "SpaceUserUpdatedPayload" then
                Decode.field "spaceUser" Data.SpaceUser.decoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder



-- INTERNAL


clientId : String -> String
clientId spaceUserId =
    "space_subscription_" ++ spaceUserId


document : Document
document =
    GraphQL.document
        """
        subscription SpaceSubscription(
          $spaceId: ID!
        ) {
          spaceSubscription(spaceId: $spaceId) {
            __typename
            ... on SpaceUpdatedPayload {
              space {
                ...SpaceFields
              }
            }
            ... on SpaceUserUpdatedPayload {
              spaceUser {
                ...SpaceUserFields
              }
            }
          }
        }
        """
        [ Data.Space.fragment
        , Data.SpaceUser.fragment
        ]


variables : String -> Maybe Encode.Value
variables spaceId =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            ]


decodeByTypename : (String -> Decode.Decoder a) -> Decode.Decoder a
decodeByTypename payloadDecoder =
    Decode.at [ "data", "spaceSubscription" ] <|
        (Decode.field "__typename" Decode.string
            |> Decode.andThen payloadDecoder
        )
