module Mutation.RegisterPushSubscription exposing (Response(..), request)

import GraphQL exposing (Document)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Session exposing (Session)
import Task exposing (Task)
import ValidationError exposing (ValidationError)
import ValidationFields


type Response
    = Success
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation RegisterPushSubscription(
          $data: String!
        ) {
          registerPushSubscription(
            data: $data
          ) {
            ...ValidationFields
          }
        }
        """
        [ ValidationFields.fragment
        ]


variables : String -> Maybe Encode.Value
variables data =
    Just <|
        Encode.object
            [ ( "data", Encode.string data )
            ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.succeed Success

        False ->
            Decode.at [ "data", "registerPushSubscription", "errors" ] (Decode.list ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "registerPushSubscription", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : String -> Session -> Task Session.Error ( Session, Response )
request data session =
    Session.request session <|
        GraphQL.request document (variables data) decoder
