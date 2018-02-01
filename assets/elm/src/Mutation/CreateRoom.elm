module Mutation.CreateRoom exposing (Params, Response(..), request, variables, decoder)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Data.Room exposing (RoomSubscription, SubscriberPolicy, roomSubscriptionDecoder, subscriberPolicyEncoder)
import Session exposing (Session)
import Data.ValidationError exposing (ValidationError, errorDecoder)
import GraphQL


type alias Params =
    { name : String
    , description : String
    , subscriberPolicy : SubscriberPolicy
    }


type Response
    = Success RoomSubscription
    | Invalid (List ValidationError)


query : String
query =
    """
      mutation CreateRoom(
        $name: String!,
        $description: String,
        $subscriberPolicy: String!
      ) {
        createRoom(
          name: $name,
          description: $description,
          subscriberPolicy: $subscriberPolicy
        ) {
          roomSubscription {
            room {
              id
              name
              description
              subscriberPolicy
            }
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
        , ( "subscriberPolicy", subscriberPolicyEncoder params.subscriberPolicy )
        ]


successDecoder : Decode.Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "roomSubscription" ] roomSubscriptionDecoder


invalidDecoder : Decode.Decoder Response
invalidDecoder =
    Decode.map Invalid <|
        Decode.at [ "errors" ] (Decode.list errorDecoder)


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "createRoom" ] <|
        Decode.oneOf [ successDecoder, invalidDecoder ]


request : Session -> Params -> Http.Request Response
request session params =
    GraphQL.request session query (Just (variables params)) decoder
