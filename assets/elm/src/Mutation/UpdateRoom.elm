module Mutation.UpdateRoom exposing (Params, Response(..), request, variables, decoder)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Data.Room exposing (RoomSubscription, SubscriberPolicy, roomDecoder, subscriberPolicyEncoder)
import Session exposing (Session)
import Data.ValidationError exposing (ValidationError, errorDecoder)
import GraphQL


type alias Params =
    { id : String
    , name : String
    , description : String
    , subscriberPolicy : SubscriberPolicy
    }


type Response
    = Success Data.Room.Room
    | Invalid (List ValidationError)


query : String
query =
    """
      mutation UpdateRoom(
        $id: ID!
        $name: String!,
        $description: String,
        $subscriberPolicy: String!
      ) {
        updateRoom(
          id: $id,
          name: $name,
          description: $description,
          subscriberPolicy: $subscriberPolicy
        ) {
          room {
            id
            name
            description
            subscriberPolicy
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
        [ ( "id", Encode.string params.id )
        , ( "name", Encode.string params.name )
        , ( "description", Encode.string params.description )
        , ( "subscriberPolicy", subscriberPolicyEncoder params.subscriberPolicy )
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
    let
        conditionalDecoder : Bool -> Decode.Decoder Response
        conditionalDecoder success =
            case success of
                True ->
                    Decode.at [ "data", "updateRoom" ] successDecoder

                False ->
                    Decode.at [ "data", "updateRoom" ] invalidDecoder
    in
        Decode.at [ "data", "updateRoom", "success" ] Decode.bool
            |> Decode.andThen conditionalDecoder


request : Params -> Session -> Http.Request Response
request params session =
    GraphQL.request session query (Just (variables params)) decoder
