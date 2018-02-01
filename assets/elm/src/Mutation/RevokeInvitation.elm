module Mutation.RevokeInvitation exposing (Params, Response(..), request, variables, decoder)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Session exposing (Session)
import Data.ValidationError exposing (ValidationError, errorDecoder)
import GraphQL


type alias Params =
    { id : String
    }


type Response
    = Success String
    | Invalid (List ValidationError)


query : String
query =
    """
      mutation RevokeInvitation(
        $id: ID!
      ) {
        revokeInvitation(
          id: $id
        ) {
          success
          invitation {
            id
          }
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
        [ ( "id", Encode.string params.id )
        ]


successDecoder : Decode.Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "revokeInvitation", "invitation", "id" ] Decode.string


invalidDecoder : Decode.Decoder Response
invalidDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "revokeInvitation", "errors" ] (Decode.list errorDecoder)


decoder : Decode.Decoder Response
decoder =
    let
        conditionalDecoder : Bool -> Decode.Decoder Response
        conditionalDecoder success =
            case success of
                True ->
                    successDecoder

                False ->
                    invalidDecoder
    in
        Decode.at [ "data", "revokeInvitation", "success" ] Decode.bool
            |> Decode.andThen conditionalDecoder


request : Session -> Params -> Http.Request Response
request session params =
    GraphQL.request session query (Just (variables params)) decoder
