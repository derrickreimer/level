module Query.InitSpace exposing (request, Params, Response)

import Session exposing (Session)
import Data.Group exposing (Group, groupDecoder)
import Data.Setup as Setup exposing (setupStateDecoder)
import Data.Space exposing (Space, SpaceUserRole, spaceDecoder, spaceRoleDecoder)
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
    { membershipId : String
    , user : User
    , space : Space
    , setupState : Setup.State
    , openInvitationUrl : Maybe String
    , role : SpaceUserRole
    , bookmarkedGroups : List Group
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
        spaceMembership(spaceId: $spaceId) {
          id
          role
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
            |> Pipeline.custom (Decode.at [ "spaceMembership", "id" ] Decode.string)
            |> Pipeline.custom (Decode.at [ "viewer" ] userDecoder)
            |> Pipeline.custom (Decode.at [ "spaceMembership", "space" ] spaceDecoder)
            |> Pipeline.custom (Decode.at [ "spaceMembership", "space", "setupState" ] setupStateDecoder)
            |> Pipeline.custom (Decode.at [ "spaceMembership", "space", "openInvitationUrl" ] (Decode.maybe Decode.string))
            |> Pipeline.custom (Decode.at [ "spaceMembership", "role" ] spaceRoleDecoder)
            |> Pipeline.custom (Decode.at [ "spaceMembership", "bookmarkedGroups" ] (Decode.list groupDecoder))
        )


request : Params -> Session -> Http.Request Response
request params session =
    GraphQL.request session query (Just (variables params)) decoder
