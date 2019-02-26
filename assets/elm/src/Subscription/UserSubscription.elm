module Subscription.UserSubscription exposing (spaceJoinedDecoder, subscribe, unsubscribe)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Json.Decode as Decode
import Json.Encode as Encode
import Post exposing (Post)
import Reply exposing (Reply)
import ResolvedSpace exposing (ResolvedSpace)
import Socket
import Space
import SpaceUser exposing (SpaceUser)
import Subscription



-- SOCKETS


subscribe : Cmd msg
subscribe =
    Subscription.send clientId document Nothing


unsubscribe : Cmd msg
unsubscribe =
    Subscription.cancel clientId



-- DECODERS


spaceJoinedDecoder : Decode.Decoder ( ResolvedSpace, SpaceUser )
spaceJoinedDecoder =
    Subscription.genericDecoder "user"
        "SpaceJoined"
        (Decode.map2 Tuple.pair
            (Decode.field "space" ResolvedSpace.decoder)
            (Decode.field "spaceUser" SpaceUser.decoder)
        )



-- INTERNAL


clientId : String
clientId =
    "user_subscription"


document : Document
document =
    GraphQL.toDocument
        """
        subscription UserSubscription {
          userSubscription {
            __typename
            ... on SpaceJoinedPayload {
              space {
                ...SpaceFields
              }
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
