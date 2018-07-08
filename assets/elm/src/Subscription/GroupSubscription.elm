module Subscription.GroupSubscription
    exposing
        ( GroupMembershipUpdatedPayload
        , clientId
        , payload
        , groupUpdatedDecoder
        , postCreatedDecoder
        , groupMembershipUpdatedDecoder
        )

import Json.Decode as Decode
import Json.Encode as Encode
import Data.Group exposing (Group)
import Data.GroupMembership
    exposing
        ( GroupMembership
        , GroupMembershipState
        )
import Connection
import Data.Post exposing (Post)
import Data.Reply
import Data.SpaceUser
import GraphQL exposing (Document)
import Socket


type alias GroupMembershipUpdatedPayload =
    { groupId : String
    , membership : GroupMembership
    , state : GroupMembershipState
    }


clientId : String -> String
clientId id =
    "group_subscription_" ++ id


payload : String -> Socket.Payload
payload groupId =
    Socket.payload (clientId groupId) document (Just (variables groupId))


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
              membership {
                state
                group {
                  id
                }
                spaceUser {
                  ...SpaceUserFields
                }
              }
            }
          }
        }
        """
        [ Connection.pageInfoFragment
        , Data.Post.fragment
        , Data.Reply.fragment
        , Data.SpaceUser.fragment
        , Data.Group.fragment
        ]


variables : String -> Encode.Value
variables groupId =
    Encode.object
        [ ( "groupId", Encode.string groupId )
        ]


decodeByTypename : (String -> Decode.Decoder a) -> Decode.Decoder a
decodeByTypename payloadDecoder =
    Decode.at [ "data", "groupSubscription" ] <|
        (Decode.field "__typename" Decode.string
            |> Decode.andThen payloadDecoder
        )


groupUpdatedDecoder : Decode.Decoder Group
groupUpdatedDecoder =
    let
        payloadDecoder typename =
            if typename == "GroupUpdatedPayload" then
                Decode.field "group" Data.Group.decoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder


postCreatedDecoder : Decode.Decoder Post
postCreatedDecoder =
    let
        payloadDecoder typename =
            if typename == "PostCreatedPayload" then
                Decode.field "post" Data.Post.decoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder


groupMembershipUpdatedDecoder : Decode.Decoder GroupMembershipUpdatedPayload
groupMembershipUpdatedDecoder =
    let
        payloadDecoder typename =
            if typename == "GroupMembershipUpdatedPayload" then
                Decode.at [ "membership" ] <|
                    (Decode.map3 GroupMembershipUpdatedPayload
                        (Decode.at [ "group", "id" ] Decode.string)
                        Data.GroupMembership.decoder
                        (Decode.at [ "state" ] Data.GroupMembership.stateDecoder)
                    )
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder
