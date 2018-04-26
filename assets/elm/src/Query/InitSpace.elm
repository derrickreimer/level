module Query.InitSpace exposing (request, Params, Response)

import Session exposing (Session)
import Data.Space exposing (Space, spaceDecoder)
import Data.User exposing (User, UserConnection, userDecoder, userConnectionDecoder)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import GraphQL


type alias Params =
    { spaceId : String
    }


type alias Response =
    { user : User
    , space : Space
    }


query : String
query =
    """
      query InitSpace(
        $spaceId: ID!
      ) {
        viewer {
          id
          firstName
          lastName
        }
        space(id: $spaceId) {
          id
          name
          slug
        }
      }
    """


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "spaceId", Encode.string params.spaceId )
        ]


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data" ] <|
        (Pipeline.decode Response
            |> Pipeline.custom (Decode.at [ "viewer" ] userDecoder)
            |> Pipeline.custom (Decode.at [ "space" ] spaceDecoder)
        )


request : Params -> Session -> Http.Request Response
request params session =
    GraphQL.request session query (Just (variables params)) decoder
