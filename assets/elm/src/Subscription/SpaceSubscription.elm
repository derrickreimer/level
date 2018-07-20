module Subscription.SpaceSubscription
    exposing
        ( subscribe
        , unsubscribe
        , spaceUserUpdatedDecoder
        )

import Json.Decode as Decode
import Json.Encode as Encode
import Data.SpaceUser exposing (SpaceUser)
import GraphQL exposing (Document)
import Socket


-- SOCKETS


subscribe : String -> Cmd msg
subscribe spaceId =
    Socket.send (clientId spaceId) document (variables spaceId)


unsubscribe : String -> Cmd msg
unsubscribe spaceId =
    Socket.cancel (clientId spaceId)



-- DECODERS


spaceUserUpdatedDecoder : Decode.Decoder SpaceUser
spaceUserUpdatedDecoder =
    let
        payloadDecoder typename =
            if typename == "SpaceUserUpdatedPayload" then
                Decode.field "spaceUser" Data.SpaceUser.decoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder



-- INTERNAL


clientId : String -> String
clientId spaceUserId =
    "space_subscription_" ++ spaceUserId


document : Document
document =
    GraphQL.document
        """
        subscription SpaceSubscription(
          $spaceId: ID!
        ) {
          spaceSubscription(spaceId: $spaceId) {
            __typename
            ... on SpaceUserUpdatedPayload {
              spaceUser {
                ...SpaceUserFields
              }
            }
          }
        }
        """
        [ Data.SpaceUser.fragment
        ]


variables : String -> Maybe Encode.Value
variables spaceId =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            ]


decodeByTypename : (String -> Decode.Decoder a) -> Decode.Decoder a
decodeByTypename payloadDecoder =
    Decode.at [ "data", "spaceSubscription" ] <|
        (Decode.field "__typename" Decode.string
            |> Decode.andThen payloadDecoder
        )
