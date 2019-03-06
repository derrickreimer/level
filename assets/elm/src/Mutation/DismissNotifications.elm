module Mutation.DismissNotifications exposing (Response(..), request, variables)

import GraphQL exposing (Document)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Post exposing (Post)
import Session exposing (Session)
import Task exposing (Task)
import ValidationError exposing (ValidationError)
import ValidationFields


type Response
    = Success (Maybe String)
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation DismissNotifications(
          $topic: String
        ) {
          dismissNotifications(
            topic: $topic
          ) {
            ...ValidationFields
            topic
          }
        }
        """
        [ ValidationFields.fragment
        ]


variables : Maybe String -> Maybe Encode.Value
variables maybeTopic =
    case maybeTopic of
        Just topic ->
            Just <|
                Encode.object
                    [ ( "topic", Encode.string topic )
                    ]

        Nothing ->
            Nothing


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.map Success <|
                Decode.at [ "data", "dismissNotifications", "topic" ] (Decode.maybe Decode.string)

        False ->
            Decode.map Invalid <|
                Decode.at [ "data", "dismissNotifications", "errors" ] (Decode.list ValidationError.decoder)


decoder : Decoder Response
decoder =
    Decode.at [ "data", "dismissNotifications", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    Session.request session <|
        GraphQL.request document maybeVariables decoder
