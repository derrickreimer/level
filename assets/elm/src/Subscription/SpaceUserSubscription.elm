module Subscription.SpaceUserSubscription
    exposing
        ( subscribe
        , unsubscribe
        , groupBookmarkedDecoder
        , groupUnbookmarkedDecoder
        )

import Json.Decode as Decode
import Json.Encode as Encode
import Data.Group exposing (Group)
import GraphQL exposing (Document)
import Ports
import Socket


-- SOCKETS


subscribe : String -> Cmd msg
subscribe spaceUserID =
    spaceUserID
        |> payload
        |> Ports.push


unsubscribe : String -> Cmd msg
unsubscribe spaceUserID =
    spaceUserID
        |> clientId
        |> Ports.cancel



-- DECODERS


groupBookmarkedDecoder : Decode.Decoder Group
groupBookmarkedDecoder =
    let
        payloadDecoder typename =
            if typename == "GroupBookmarkedPayload" then
                Decode.field "group" Data.Group.decoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder


groupUnbookmarkedDecoder : Decode.Decoder Group
groupUnbookmarkedDecoder =
    let
        payloadDecoder typename =
            if typename == "GroupUnbookmarkedPayload" then
                Decode.field "group" Data.Group.decoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder



-- INTERNAL


clientId : String -> String
clientId spaceUserId =
    "space_user_subscription_" ++ spaceUserId


payload : String -> Socket.Payload
payload spaceUserId =
    Socket.payload (clientId spaceUserId) document (Just (variables spaceUserId))


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
          }
        }
        """
        [ Data.Group.fragment
        ]


variables : String -> Encode.Value
variables spaceUserId =
    Encode.object
        [ ( "spaceUserId", Encode.string spaceUserId )
        ]


decodeByTypename : (String -> Decode.Decoder a) -> Decode.Decoder a
decodeByTypename payloadDecoder =
    Decode.at [ "data", "spaceUserSubscription" ] <|
        (Decode.field "__typename" Decode.string
            |> Decode.andThen payloadDecoder
        )
