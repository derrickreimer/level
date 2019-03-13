module Subscription.UserSubscription exposing (notificationCreatedDecoder, notificationDismissedDecoder, notificationsDismissedDecoder, spaceJoinedDecoder, subscribe, unsubscribe)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Json.Decode as Decode
import Json.Encode as Encode
import Notification
import Post exposing (Post)
import Reply exposing (Reply)
import ResolvedNotification exposing (ResolvedNotification)
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


notificationCreatedDecoder : Decode.Decoder ResolvedNotification
notificationCreatedDecoder =
    Subscription.decoder "user"
        "NotificationCreated"
        "notification"
        ResolvedNotification.decoder


notificationDismissedDecoder : Decode.Decoder ResolvedNotification
notificationDismissedDecoder =
    Subscription.decoder "user"
        "NotificationDismissed"
        "notification"
        ResolvedNotification.decoder


notificationsDismissedDecoder : Decode.Decoder (Maybe String)
notificationsDismissedDecoder =
    Subscription.decoder "user"
        "NotificationsDismissed"
        "topic"
        (Decode.maybe Decode.string)



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
            ... on NotificationCreatedPayload {
              notification {
                ...NotificationFields
              }
            }
            ... on NotificationDismissedPayload {
              notification {
                ...NotificationFields
              }
            }
            ... on NotificationsDismissedPayload {
              topic
            }
          }
        }
        """
        [ Space.fragment
        , SpaceUser.fragment
        , Notification.fragment
        ]
