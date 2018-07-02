module Subscription.SpaceUserSubscription
    exposing
        ( clientId
        , payload
        , groupBookmarkedDecoder
        , groupUnbookmarkedDecoder
        )

import Json.Decode as Decode
import Json.Encode as Encode
import Data.Group exposing (Group, groupDecoder)
import GraphQL
import Socket


clientId : String -> String
clientId spaceUserId =
    "space_user_subscription_" ++ spaceUserId


payload : String -> Socket.Payload
payload spaceUserId =
    Socket.Payload (clientId spaceUserId) query (Just (variables spaceUserId))


query : String
query =
    GraphQL.query
        [ """
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
        , Data.Group.fragment
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


groupBookmarkedDecoder : Decode.Decoder Group
groupBookmarkedDecoder =
    let
        payloadDecoder typename =
            if typename == "GroupBookmarkedPayload" then
                Decode.field "group" groupDecoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder


groupUnbookmarkedDecoder : Decode.Decoder Group
groupUnbookmarkedDecoder =
    let
        payloadDecoder typename =
            if typename == "GroupUnbookmarkedPayload" then
                Decode.field "group" groupDecoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder
