module Subscription.SpaceSubscription exposing (spaceUpdatedDecoder, spaceUserUpdatedDecoder, subscribe, unsubscribe)

import GraphQL exposing (Document)
import Json.Decode as Decode
import Json.Encode as Encode
import Socket
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Subscription



-- SOCKETS


subscribe : String -> Cmd msg
subscribe spaceId =
    Subscription.send (clientId spaceId) document (variables spaceId)


unsubscribe : String -> Cmd msg
unsubscribe spaceId =
    Subscription.cancel (clientId spaceId)



-- DECODERS


spaceUpdatedDecoder : Decode.Decoder Space
spaceUpdatedDecoder =
    Subscription.decoder "space"
        "SpaceUpdated"
        "space"
        Space.decoder


spaceUserUpdatedDecoder : Decode.Decoder SpaceUser
spaceUserUpdatedDecoder =
    Subscription.decoder "space"
        "SpaceUserUpdated"
        "spaceUser"
        SpaceUser.decoder



-- INTERNAL


clientId : String -> String
clientId spaceId =
    "space_subscription_" ++ spaceId


document : Document
document =
    GraphQL.toDocument
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
        [ Space.fragment
        , SpaceUser.fragment
        ]


variables : String -> Maybe Encode.Value
variables spaceId =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            ]
