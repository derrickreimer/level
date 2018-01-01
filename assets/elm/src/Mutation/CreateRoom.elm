module Mutation.CreateRoom exposing (Params, Response(..), request, variables, decoder)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Data.Room exposing (Room, roomDecoder)
import Data.ValidationError exposing (ValidationError, errorDecoder)
import GraphQL


type alias Params =
    { name : String
    , description : String
    }


type Response
    = Success Room
    | Invalid (List ValidationError)


query : String
query =
    """
      mutation CreateRoom(
        $name: String!,
        $description: String
      ) {
        createRoom(
          name: $name,
          description: $description
        ) {
          room {
            id
            name
            description
          }
          success
          errors {
            attribute
            message
          }
        }
      }
    """


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "name", Encode.string params.name )
        , ( "description", Encode.string params.description )
        ]


successDecoder : Decode.Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "room" ] roomDecoder


invalidDecoder : Decode.Decoder Response
invalidDecoder =
    Decode.map Invalid <|
        Decode.at [ "errors" ] (Decode.list errorDecoder)


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "createRoom" ] <|
        Decode.oneOf [ successDecoder, invalidDecoder ]


request : String -> Params -> Http.Request Response
request apiToken params =
    GraphQL.request apiToken query (Just (variables params)) decoder
