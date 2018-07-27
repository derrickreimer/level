module Subscription.GroupSubscription
    exposing
        ( subscribe
        , unsubscribe
        , groupUpdatedDecoder
        , postCreatedDecoder
        , groupMembershipUpdatedDecoder
        )

import Json.Decode as Decode
import Json.Encode as Encode
import Data.Group as Group exposing (Group)
import Data.Post as Post exposing (Post)
import GraphQL exposing (Document)
import Socket


-- SOCKETS


subscribe : String -> Cmd msg
subscribe groupId =
    Socket.send (clientId groupId) document (variables groupId)


unsubscribe : String -> Cmd msg
unsubscribe groupId =
    Socket.cancel (clientId groupId)



-- DECODERS


groupUpdatedDecoder : Decode.Decoder Group
groupUpdatedDecoder =
    let
        payloadDecoder typename =
            if typename == "GroupUpdatedPayload" then
                Decode.field "group" Group.decoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder


postCreatedDecoder : Decode.Decoder Post
postCreatedDecoder =
    let
        payloadDecoder typename =
            if typename == "PostCreatedPayload" then
                Decode.field "post" Post.decoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder


groupMembershipUpdatedDecoder : Decode.Decoder Group
groupMembershipUpdatedDecoder =
    let
        payloadDecoder typename =
            if typename == "GroupMembershipUpdatedPayload" then
                Decode.field "group" Group.decoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder



-- INTERNAL


clientId : String -> String
clientId id =
    "group_subscription_" ++ id


document : Document
document =
    GraphQL.document
        """
        subscription GroupSubscription(
          $groupId: ID!
        ) {
          groupSubscription(groupId: $groupId) {
            __typename
            ... on GroupUpdatedPayload {
              group {
                ...GroupFields
              }
            }
            ... on PostCreatedPayload {
              post {
                ...PostFields
              }
            }
            ... on GroupMembershipUpdatedPayload {
              group {
                ...GroupFields
              }
            }
          }
        }
        """
        [ Post.fragment 5
        , Group.fragment
        ]


variables : String -> Maybe Encode.Value
variables groupId =
    Just <|
        Encode.object
            [ ( "groupId", Encode.string groupId )
            ]


decodeByTypename : (String -> Decode.Decoder a) -> Decode.Decoder a
decodeByTypename payloadDecoder =
    Decode.at [ "data", "groupSubscription" ] <|
        (Decode.field "__typename" Decode.string
            |> Decode.andThen payloadDecoder
        )
