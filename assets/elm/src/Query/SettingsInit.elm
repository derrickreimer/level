module Query.SettingsInit exposing (Response, request)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Repo exposing (Repo)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , space : Space
    , isDigestEnabled : Bool
    , repo : Repo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , isDigestEnabled : Bool
    }


document : Document
document =
    GraphQL.toDocument
        """
        query GroupInit(
          $spaceSlug: String!
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            digest {
              isEnabled
            }
            space {
              ...SpaceFields
            }
            bookmarks {
              ...GroupFields
            }
          }
        }
        """
        [ Group.fragment
        , SpaceUser.fragment
        , Space.fragment
        ]


variables : String -> Maybe Encode.Value
variables spaceSlug =
    Just <|
        Encode.object
            [ ( "spaceSlug", Encode.string spaceSlug )
            ]


decoder : Decoder Data
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        (Decode.succeed Data
            |> Pipeline.custom SpaceUser.decoder
            |> Pipeline.custom (Decode.field "space" Space.decoder)
            |> Pipeline.custom (Decode.field "bookmarks" (Decode.list Group.decoder))
            |> Pipeline.custom (Decode.at [ "digest", "isEnabled" ] Decode.bool)
        )


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpaceUser data.viewer
                |> Repo.setSpace data.space
                |> Repo.setGroups data.bookmarks

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.bookmarks)
                data.space
                data.isDigestEnabled
                repo
    in
    ( session, resp )


request : String -> Session -> Task Session.Error ( Session, Response )
request spaceSlug session =
    GraphQL.request document (variables spaceSlug) decoder
        |> Session.request session
        |> Task.map buildResponse
