module Query.MainInit exposing (Response, request)

import GraphQL exposing (Document)
import Group exposing (Group)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Session exposing (Session)
import Setup exposing (setupStateDecoder)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
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
        [ SpaceUser.fragment
        , Space.fragment
        , Group.fragment
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
            |> Pipeline.custom SpaceUser.decoder
            |> Pipeline.custom (Decode.at [ "space" ] Space.decoder)
            |> Pipeline.custom (Decode.at [ "space", "setupState" ] setupStateDecoder)
            |> Pipeline.custom (Decode.at [ "space", "openInvitationUrl" ] (Decode.maybe Decode.string))
            |> Pipeline.custom (Decode.at [ "bookmarkedGroups" ] (Decode.list Group.decoder))
            |> Pipeline.custom (Decode.at [ "space", "featuredUsers" ] (Decode.list SpaceUser.decoder))
        )


request : String -> Session -> Task Session.Error ( Session, Response )
request spaceId session =
    Session.request session <|
        GraphQL.request document (variables spaceId) decoder
