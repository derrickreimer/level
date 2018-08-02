module Subscription.SpaceSubscription
    exposing
        ( subscribe
        , unsubscribe
        , spaceUpdatedDecoder
        , spaceUserUpdatedDecoder
        )

import Json.Decode as Decode
import Json.Encode as Encode
import Data.Space as Space exposing (Space)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import GraphQL exposing (Document)
import Socket
import Subscription


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
        [ Space.fragment
        , SpaceUser.fragment
        ]


variables : String -> Maybe Encode.Value
variables spaceId =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            ]
