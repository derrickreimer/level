module Query.SharedState exposing (request, Params, Response)

import Session exposing (Session)
import Data.Group exposing (Group, groupDecoder)
import Data.Setup as Setup exposing (setupStateDecoder)
import Data.Space exposing (Space, SpaceUserRole, spaceDecoder, spaceRoleDecoder)
import Data.SpaceUser exposing (SpaceUser, Role, spaceUserDecoder)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import GraphQL


type alias Params =
    { spaceId : String
    }


type alias Response =
    { user : SpaceUser
    , space : Space
    , setupState : Setup.State
    , openInvitationUrl : Maybe String
    , bookmarkedGroups : List Group
    }


query : String
query =
    """
      query SharedState(
        $spaceId: ID!
      ) {
        spaceUser(spaceId: $spaceId) {
          id
          role
          firstName
          lastName
          space {
            id
            name
            slug
            setupState
            openInvitationUrl
          }
          bookmarkedGroups {
            id
            name
          }
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
            |> Pipeline.custom (Decode.at [ "spaceUser" ] spaceUserDecoder)
            |> Pipeline.custom (Decode.at [ "spaceUser", "space" ] spaceDecoder)
            |> Pipeline.custom (Decode.at [ "spaceUser", "space", "setupState" ] setupStateDecoder)
            |> Pipeline.custom (Decode.at [ "spaceUser", "space", "openInvitationUrl" ] (Decode.maybe Decode.string))
            |> Pipeline.custom (Decode.at [ "spaceUser", "bookmarkedGroups" ] (Decode.list groupDecoder))
        )


request : Params -> Session -> Http.Request Response
request params =
    GraphQL.request query (Just (variables params)) decoder
