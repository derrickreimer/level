module Query.SetupInit exposing (Response, request)

import Connection exposing (Connection)
import DigestSettings exposing (DigestSettings)
import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Nudge exposing (Nudge)
import Repo exposing (Repo)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewerId : Id
    , spaceId : Id
    , groupIds : List Id
    , spaceUserIds : List Id
    , space : Space
    , digestSettings : DigestSettings
    , nudges : List Nudge
    , timeZone : String
    , repo : Repo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , groups : List Group
    , spaceUsers : List SpaceUser
    , digestSettings : DigestSettings
    , nudges : List Nudge
    , timeZone : String
    }


document : Document
document =
    GraphQL.toDocument
        """
        query SetupInit(
          $spaceSlug: String!
        ) {
          viewer {
            timeZone
          }
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            nudges {
              ...NudgeFields
            }
            digestSettings {
              ...DigestSettingsFields
            }
            space {
              ...SpaceFields
            }
          }
        }
        """
        [ SpaceUser.fragment
        , Space.fragment
        , DigestSettings.fragment
        , Nudge.fragment
        ]


variables : String -> Maybe Encode.Value
variables spaceSlug =
    Just <|
        Encode.object
            [ ( "spaceSlug", Encode.string spaceSlug )
            ]


decoder : Decoder Data
decoder =
    Decode.at [ "data" ] <|
        (Decode.succeed Data
            |> Pipeline.custom (Decode.field "spaceUser" SpaceUser.decoder)
            |> Pipeline.custom (Decode.at [ "spaceUser", "space" ] Space.decoder)
            |> Pipeline.custom (Decode.at [ "spaceUser", "space", "groups", "edges" ] (Decode.list (Decode.field "node" Group.decoder)))
            |> Pipeline.custom (Decode.at [ "spaceUser", "space", "spaceUsers", "edges" ] (Decode.list (Decode.field "node" SpaceUser.decoder)))
            |> Pipeline.custom (Decode.at [ "spaceUser", "digestSettings" ] DigestSettings.decoder)
            |> Pipeline.custom (Decode.at [ "spaceUser", "nudges" ] (Decode.list Nudge.decoder))
            |> Pipeline.custom (Decode.at [ "viewer", "timeZone" ] Decode.string)
        )


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpaceUser data.viewer
                |> Repo.setSpace data.space
                |> Repo.setSpace data.space
                |> Repo.setGroups data.groups
                |> Repo.setSpaceUsers data.spaceUsers

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.groups)
                (List.map SpaceUser.id data.spaceUsers)
                data.space
                data.digestSettings
                data.nudges
                data.timeZone
                repo
    in
    ( session, resp )


request : String -> Session -> Task Session.Error ( Session, Response )
request spaceSlug session =
    GraphQL.request document (variables spaceSlug) decoder
        |> Session.request session
        |> Task.map buildResponse
