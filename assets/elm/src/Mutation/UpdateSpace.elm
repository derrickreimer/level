module Mutation.UpdateSpace exposing (Response(..), request)

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Data.Space exposing (Space)
import Data.ValidationFields
import Data.ValidationError exposing (ValidationError)
import Session exposing (Session)
import GraphQL exposing (Document)


type Response
    = Success Space
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.document
        """
        mutation UpdateSpace(
          $spaceId: ID!,
          $name: String,
          $slug: String
        ) {
          updateSpace(
            spaceId: $spaceId,
            name: $name,
            slug: $slug
          ) {
            ...ValidationFields
            space {
              ...SpaceFields
            }
          }
        }
        """
        [ Data.Space.fragment
        , Data.ValidationFields.fragment
        ]


variables : String -> String -> String -> Maybe Encode.Value
variables spaceId name slug =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "name", Encode.string name )
            , ( "slug", Encode.string slug )
            ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "updateSpace", "space" ] Data.Space.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "updateSpace", "errors" ] (Decode.list Data.ValidationError.decoder)


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
        Decode.at [ "data", "updateSpace", "success" ] Decode.bool
            |> Decode.andThen conditionalDecoder


request : String -> String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceId name slug session =
    Session.request session <|
        GraphQL.request document (variables spaceId name slug) decoder
