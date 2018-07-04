module Mutation.CreateSpace exposing (Params, Response(..), request, decoder)

import Http
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Data.Space exposing (Space)
import Data.ValidationError exposing (ValidationError)
import Session exposing (Session)
import GraphQL exposing (Document)


type alias Params =
    { name : String
    , slug : String
    }


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
            success
            space {
              ...SpaceFields
            }
            errors {
              attribute
              message
            }
          }
        }
        """
        [ Data.Space.fragment
        ]


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "name", Encode.string params.name )
        , ( "slug", Encode.string params.slug )
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


request : Params -> Session -> Http.Request Response
request params =
    GraphQL.request document (Just (variables params)) decoder
