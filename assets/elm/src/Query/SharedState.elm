module Query.SharedState exposing (request, Params, Response)

import Session exposing (Session)
import Data.Group exposing (Group)
import Data.Setup as Setup exposing (setupStateDecoder)
import Data.Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
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
            ...SpaceUserFields
            space {
              ...SpaceFields
              setupState
              openInvitationUrl
              featuredUsers {
                ...SpaceUserFields
              }
            }
            bookmarkedGroups {
              ...GroupFields
            }
          }
        }
        """
        [ Data.SpaceUser.fragment
        , Data.Space.fragment
        , Data.Group.fragment
        ]


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "spaceId", Encode.string params.spaceId )
        ]


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        (Pipeline.decode Response
            |> Pipeline.custom Data.SpaceUser.decoder
            |> Pipeline.custom (Decode.at [ "space" ] Data.Space.decoder)
            |> Pipeline.custom (Decode.at [ "space", "setupState" ] setupStateDecoder)
            |> Pipeline.custom (Decode.at [ "space", "openInvitationUrl" ] (Decode.maybe Decode.string))
            |> Pipeline.custom (Decode.at [ "bookmarkedGroups" ] (Decode.list Data.Group.decoder))
            |> Pipeline.custom (Decode.at [ "space", "featuredUsers" ] (Decode.list Data.SpaceUser.decoder))
        )


request : Params -> Session -> Http.Request Response
request params =
    GraphQL.request document (Just (variables params)) decoder
