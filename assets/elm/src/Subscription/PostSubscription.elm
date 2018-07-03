module Subscription.PostSubscription
    exposing
        ( clientId
        , payload
        , replyCreatedDecoder
        )

import Json.Decode as Decode
import Json.Encode as Encode
import Data.SpaceUser
import Data.Reply exposing (Reply, replyDecoder)
import GraphQL
import Socket


clientId : String -> String
clientId id =
    "post_subscription_" ++ id


payload : String -> Socket.Payload
payload postId =
    Socket.Payload (clientId postId) query (Just (variables postId))


query : String
query =
    GraphQL.query
        [ """
          subscription PostSubscription(
            $postId: ID!
          ) {
            postSubscription(postId: $postId) {
              __typename
              ... on ReplyCreatedPayload {
                reply {
                  ...ReplyFields
                }
              }
            }
          }
          """
        , Data.Reply.fragment
        , Data.SpaceUser.fragment
        ]


variables : String -> Encode.Value
variables postId =
    Encode.object
        [ ( "postId", Encode.string postId )
        ]


decodeByTypename : (String -> Decode.Decoder a) -> Decode.Decoder a
decodeByTypename payloadDecoder =
    Decode.at [ "data", "postSubscription" ] <|
        (Decode.field "__typename" Decode.string
            |> Decode.andThen payloadDecoder
        )


replyCreatedDecoder : Decode.Decoder Reply
replyCreatedDecoder =
    let
        payloadDecoder typename =
            if typename == "ReplyCreated" then
                Decode.field "reply" replyDecoder
            else
                Decode.fail "payload does not match"
    in
        decodeByTypename payloadDecoder
