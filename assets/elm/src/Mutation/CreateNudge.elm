module Mutation.CreateNudge exposing (Response(..), request, variables)

import GraphQL exposing (Document)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Nudge exposing (Nudge)
import Session exposing (Session)
import Task exposing (Task)
import ValidationError exposing (ValidationError)
import ValidationFields


type Response
    = Success Nudge
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation CreateNudge(
          $spaceId: ID!,
          $minute: Int!
        ) {
          createNudge(
            spaceId: $spaceId,
            minute: $minute
          ) {
            ...ValidationFields
            nudge {
              ...NudgeFields
            }
          }
        }
        """
        [ Nudge.fragment
        , ValidationFields.fragment
        ]


variables : Id -> Int -> Maybe Encode.Value
variables spaceId minute =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "minute", Encode.int minute )
            ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "createNudge", "nudge" ] Nudge.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "createNudge", "errors" ]
            (Decode.list ValidationError.decoder)


decoder : Decoder Response
decoder =
    let
        conditionalDecoder : Bool -> Decoder Response
        conditionalDecoder success =
            case success of
                True ->
                    successDecoder

                False ->
                    failureDecoder
    in
    Decode.at [ "data", "createNudge", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    Session.request session <|
        GraphQL.request document maybeVariables decoder
