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
    , spaceUserId : Id
    , role : SpaceUser.Role
    , repo : Repo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , spaceUser : SpaceUser
    }


document : Document
document =
    GraphQL.toDocument
        """
        query SpaceUsersInit(
          $spaceSlug: ID!,
          $spaceUserId: ID!
        ) {
          viewingUser: spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            space {
              ...SpaceFields
            }
            bookmarks {
              ...GroupFields
            }
          }
          viewedUser: spaceUser(id: $spaceUserId) {
            ...SpaceUserFields
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
    Decode.at [ "data" ] <|
        Decode.map4 Data
            (field "viewingUser" SpaceUser.decoder)
            (Decode.at [ "viewingUser", "space" ] Space.decoder)
            (Decode.at [ "viewingUser", "bookmarks" ] (list Group.decoder))
            (field "viewedUser" SpaceUser.decoder)


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpaceUser data.viewer
                |> Repo.setSpaceUser data.spaceUser
                |> Repo.setSpace data.space
                |> Repo.setGroups data.bookmarks

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.bookmarks)
                (SpaceUser.id data.spaceUser)
                (SpaceUser.role data.spaceUser)
                repo
    in
    ( session, resp )


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    GraphQL.request document maybeVariables decoder
        |> Session.request session
        |> Task.map buildResponse
