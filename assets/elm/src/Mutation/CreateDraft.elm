module Mutation.CreateDraft exposing (Params, request)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Session exposing (Session)
import GraphQL


type alias Params =
    { subject : String
    , body : String
    , recipientIds : List String
    }


query : String
query =
    """
      mutation CreateDraft(
        $subject: String!,
        $body: String!,
        $recipientIds: [String!]
      ) {
        createDraft(
          subject: $subject,
          body: $body,
          recipientIds: $recipientIds
        ) {
          draft {
            id
            subject
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
        [ ( "subject", Encode.string params.subject )
        , ( "body", Encode.string params.body )
        , ( "recipientIds", Encode.list (List.map Encode.string params.recipientIds) )
        ]


decoder : Decode.Decoder Bool
decoder =
    Decode.at [ "data", "createDraft", "success" ] Decode.bool


request : Session -> Params -> Http.Request Bool
request session params =
    GraphQL.request session query (Just (variables params)) decoder
