module Mutation.CreateInvitation exposing (Params, Response(..), request, variables, decoder)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Data.ValidationError exposing (ValidationError, errorDecoder)
import GraphQL


type alias Params =
    { email : String
    }


type Response
    = Success
    | Invalid (List ValidationError)


query : String
query =
    """
      mutation CreateInvitation(
        $email: String!
      ) {
        inviteUser(
          email: $email
        ) {
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
        [ ( "email", Encode.string params.email )
        ]


invalidDecoder : Decode.Decoder Response
invalidDecoder =
    Decode.map Invalid <|
        Decode.at [ "errors" ] (Decode.list errorDecoder)


decoder : Decode.Decoder Response
decoder =
    let
        conditionalDecoder : Bool -> Decode.Decoder Response
        conditionalDecoder success =
            case success of
                True ->
                    Decode.succeed Success

                False ->
                    Decode.at [ "data", "inviteUser" ] invalidDecoder
    in
        Decode.at [ "data", "inviteUser", "success" ] Decode.bool
            |> Decode.andThen conditionalDecoder


request : String -> Params -> Http.Request Response
request apiToken params =
    GraphQL.request apiToken query (Just (variables params)) decoder
