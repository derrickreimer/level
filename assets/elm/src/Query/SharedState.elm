module Query.SharedState exposing (request, Params, Response)

import Session exposing (Session)
import Data.Group exposing (Group)
import Data.Setup as Setup exposing (setupStateDecoder)
import Data.Space exposing (Space, SpaceUserRole, spaceDecoder, spaceRoleDecoder)
import Data.SpaceUser exposing (SpaceUser, Role, spaceUserDecoder)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import GraphQL exposing (Document)


type alias Params =
    { spaceId : String
    }


type alias Response =
    { user : SpaceUser
    , space : Space
    , setupState : Setup.State
    , openInvitationUrl : Maybe String
    , bookmarkedGroups : List Group
    , featuredUsers : List SpaceUser
    }


document : Document
document =
    GraphQL.document
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
              featuredUsers {
                id
                firstName
                lastName
                role
              }
            }
            bookmarkedGroups {
              id
              name
            }
          }
        }
        """
        []


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
            |> Pipeline.custom (Decode.at [ "spaceUser", "bookmarkedGroups" ] (Decode.list Data.Group.decoder))
            |> Pipeline.custom (Decode.at [ "spaceUser", "space", "featuredUsers" ] (Decode.list spaceUserDecoder))
        )


request : Params -> Session -> Http.Request Response
request params =
    GraphQL.request document (Just (variables params)) decoder
