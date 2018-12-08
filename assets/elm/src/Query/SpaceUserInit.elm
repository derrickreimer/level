module Query.SpaceUserInit exposing (Response, request, variables)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import Repo exposing (Repo)
import Route.SpaceUser exposing (Params(..))
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , repo : Repo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    }


document : Document
document =
    GraphQL.toDocument
        """
        query SpaceUsersInit(
          $spaceSlug: ID!
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            space {
              ...SpaceFields
            }
            bookmarks {
              ...GroupFields
            }
          }
        }
        """
        [ SpaceUser.fragment
        , Space.fragment
        , Group.fragment
        , Connection.fragment "SpaceUserConnection" SpaceUser.fragment
        ]


variables : Params -> Maybe Encode.Value
variables params =
    Just <|
        Encode.object
            [ ( "spaceSlug", Encode.string (Route.SpaceUser.getSpaceSlug params) )
            , ( "spaceUserId", Encode.string (Route.SpaceUser.getSpaceUserId params) )
            ]


decoder : Decoder Data
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        Decode.map3 Data
            SpaceUser.decoder
            (field "space" Space.decoder)
            (field "bookmarks" (list Group.decoder))


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
                repo
    in
    ( session, resp )


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    GraphQL.request document maybeVariables decoder
        |> Session.request session
        |> Task.map buildResponse
