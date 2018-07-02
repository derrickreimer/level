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
import Data.Group exposing (Group, groupDecoder)
import Data.GroupMembership
    exposing
        ( GroupMembership
        , GroupMembershipState
        , groupMembershipDecoder
        , groupMembershipStateDecoder
        )
import Data.Post exposing (Post, postDecoder)
import GraphQL
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
    Socket.Payload (clientId groupId) query (Just (variables groupId))


query : String
query =
    GraphQL.query
        [ """
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
                      id
                      firstName
                      lastName
                      role
                    }
                  }
                }
              }
            }
          """
        , Data.Post.fragment
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
            if typename == "GroupUpdated" then
                Decode.field "group" groupDecoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder


postCreatedDecoder : Decode.Decoder Post
postCreatedDecoder =
    let
        payloadDecoder typename =
            if typename == "PostCreatedPayload" then
                Decode.field "post" postDecoder
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
                        groupMembershipDecoder
                        (Decode.at [ "state" ] groupMembershipStateDecoder)
                    )
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder
