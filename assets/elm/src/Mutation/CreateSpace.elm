module Mutation.CreateSpace exposing (Response(..), request)

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
        [ Data.Space.fragment
        , Data.ValidationFields.fragment
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
        Decode.at [ "data", "createSpace", "space" ] Data.Space.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "createSpace", "errors" ]
            (Decode.list Data.ValidationError.decoder)


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
