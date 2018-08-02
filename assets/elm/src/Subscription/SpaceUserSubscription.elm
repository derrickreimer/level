module Subscription.SpaceUserSubscription
    exposing
        ( subscribe
        , unsubscribe
        , groupBookmarkedDecoder
        , groupUnbookmarkedDecoder
        , postSubscribedDecoder
        , postUnsubscribedDecoder
        )

import Json.Decode as Decode
import Json.Encode as Encode
import Data.Group as Group exposing (Group)
import Data.Post as Post exposing (Post)
import GraphQL exposing (Document)
import Socket


-- SOCKETS


subscribe : String -> Cmd msg
subscribe spaceUserId =
    Socket.send (clientId spaceUserId) document (variables spaceUserId)


unsubscribe : String -> Cmd msg
unsubscribe spaceUserId =
    Socket.cancel (clientId spaceUserId)



-- DECODERS


groupBookmarkedDecoder : Decode.Decoder Group
groupBookmarkedDecoder =
    let
        payloadDecoder typename =
            if typename == "GroupBookmarkedPayload" then
                Decode.field "group" Group.decoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder


groupUnbookmarkedDecoder : Decode.Decoder Group
groupUnbookmarkedDecoder =
    let
        payloadDecoder typename =
            if typename == "GroupUnbookmarkedPayload" then
                Decode.field "group" Group.decoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder


postSubscribedDecoder : Decode.Decoder Post
postSubscribedDecoder =
    let
        payloadDecoder typename =
            if typename == "PostSubscribedPayload" then
                Decode.field "post" Post.decoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder


postUnsubscribedDecoder : Decode.Decoder Post
postUnsubscribedDecoder =
    let
        payloadDecoder typename =
            if typename == "PostUnsubscribedPayload" then
                Decode.field "post" Post.decoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder



-- INTERNAL


clientId : String -> String
clientId spaceUserId =
    "space_user_subscription_" ++ spaceUserId


document : Document
document =
    GraphQL.document
        """
        subscription SpaceUserSubscription(
          $spaceUserId: ID!
        ) {
          spaceUserSubscription(spaceUserId: $spaceUserId) {
            __typename
            ... on GroupBookmarkedPayload {
              group {
                ...GroupFields
              }
            }
            ... on GroupUnbookmarkedPayload {
              group {
                ...GroupFields
              }
            }
            ... on PostSubscribedPayload {
              post {
                ...PostFields
              }
            }
            ... on PostUnsubscribedPayload {
              post {
                ...PostFields
              }
            }
          }
        }
        """
        [ Group.fragment
        , Post.fragment 5
        ]


variables : String -> Maybe Encode.Value
variables spaceUserId =
    Just <|
        Encode.object
            [ ( "spaceUserId", Encode.string spaceUserId )
            ]


decodeByTypename : (String -> Decode.Decoder a) -> Decode.Decoder a
decodeByTypename payloadDecoder =
    Decode.at [ "data", "spaceUserSubscription" ] <|
        (Decode.field "__typename" Decode.string
            |> Decode.andThen payloadDecoder
        )
