module Query.InitSpace exposing (request, Params, Response)

import Session exposing (Session)
import Data.Setup as Setup exposing (setupStateDecoder)
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
    , setupState : Setup.State
    , openInvitationUrl : Maybe String
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
          setupState
          openInvitationUrl
          viewerRole
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
            |> Pipeline.custom (Decode.at [ "space", "setupState" ] setupStateDecoder)
            |> Pipeline.custom (Decode.at [ "space", "openInvitationUrl" ] (Decode.maybe Decode.string))
        )


request : Params -> Session -> Http.Request Response
request params session =
    GraphQL.request session query (Just (variables params)) decoder
