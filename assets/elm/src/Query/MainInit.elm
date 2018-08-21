module Query.MainInit exposing (Response, request)

import Data.Group exposing (Group)
import Data.Setup as Setup exposing (setupStateDecoder)
import Data.Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import GraphQL exposing (Document)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Session exposing (Session)
import Task exposing (Task)


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
    GraphQL.toDocument
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


variables : String -> Maybe Encode.Value
variables spaceId =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            ]


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        (Decode.succeed Response
            |> Pipeline.custom Data.SpaceUser.decoder
            |> Pipeline.custom (Decode.at [ "space" ] Data.Space.decoder)
            |> Pipeline.custom (Decode.at [ "space", "setupState" ] setupStateDecoder)
            |> Pipeline.custom (Decode.at [ "space", "openInvitationUrl" ] (Decode.maybe Decode.string))
            |> Pipeline.custom (Decode.at [ "bookmarkedGroups" ] (Decode.list Data.Group.decoder))
            |> Pipeline.custom (Decode.at [ "space", "featuredUsers" ] (Decode.list Data.SpaceUser.decoder))
        )


request : String -> Session -> Task Session.Error ( Session, Response )
request spaceId session =
    Session.request session <|
        GraphQL.request document (variables spaceId) decoder
