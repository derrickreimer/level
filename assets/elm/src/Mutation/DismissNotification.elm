module Mutation.DismissNotification exposing (Response(..), request, variables)

import GraphQL exposing (Document)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Notification
import Post exposing (Post)
import ResolvedNotification exposing (ResolvedNotification)
import Session exposing (Session)
import Task exposing (Task)
import ValidationError exposing (ValidationError)
import ValidationFields


type Response
    = Success ResolvedNotification
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation DismissNotification(
          $id: ID
        ) {
          dismissNotification(
            id: $id
          ) {
            ...ValidationFields
            notification {
              ...NotificationFields
            }
          }
        }
        """
        [ ValidationFields.fragment
        , Notification.fragment
        ]


variables : Id -> Maybe Encode.Value
variables id =
    Just <|
        Encode.object
            [ ( "id", Encode.string id )
            ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.map Success <|
                Decode.at [ "data", "dismissNotification", "notification" ] ResolvedNotification.decoder

        False ->
            Decode.map Invalid <|
                Decode.at [ "data", "dismissNotification", "errors" ] (Decode.list ValidationError.decoder)


decoder : Decoder Response
decoder =
    Decode.at [ "data", "dismissNotification", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    Session.request session <|
        GraphQL.request document maybeVariables decoder
