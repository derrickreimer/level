module Mutation.CreateSpace exposing (Response(..), request)

import GraphQL exposing (Document)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Session exposing (Session)
import Space exposing (Space)
import Task exposing (Task)
import ValidationError exposing (ValidationError)
import ValidationFields


type Response
    = Success Space
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation CreateSpace(
          $name: String!,
          $slug: String!
        ) {
          createSpace(
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
        [ Space.fragment
        , ValidationFields.fragment
        ]


variables : String -> String -> Maybe Encode.Value
variables name slug =
    Just <|
        Encode.object
            [ ( "name", Encode.string name )
            , ( "slug", Encode.string slug )
            ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "createSpace", "space" ] Space.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "createSpace", "errors" ]
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
    Decode.at [ "data", "createSpace", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : String -> String -> Session -> Task Session.Error ( Session, Response )
request name slug session =
    Session.request session <|
        GraphQL.request document (variables name slug) decoder
