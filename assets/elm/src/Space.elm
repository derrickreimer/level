module Space exposing (Space, avatar, avatarUrl, canUpdate, decoder, fragment, id, name, openInvitationUrl, slug)

import Avatar
import Connection exposing (Connection)
import GraphQL exposing (Fragment)
import Group exposing (Group)
import Html exposing (Html)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, field, int, list, maybe, string)
import Json.Decode.Pipeline as Pipeline exposing (custom, required)
import Json.Encode as Encode
import Route exposing (Route)
import Route.Inbox
import SpaceUser exposing (SpaceUser)



-- TYPES


type Space
    = Space Data


type alias Data =
    { id : Id
    , name : String
    , slug : String
    , avatarUrl : Maybe String
    , openInvitationUrl : Maybe String
    , spaceUserIds : List Id
    , groupIds : List Id
    , canUpdate : Bool
    , fetchedAt : Int
    }


fragment : Fragment
fragment =
    GraphQL.toFragment
        """
        fragment SpaceFields on Space {
          id
          name
          slug
          avatarUrl
          openInvitationUrl
          spaceUsers(first: 1000) {
            ...SpaceUserConnectionFields
          }
          groups(first: 1000) {
            ...GroupConnectionFields
          }
          canUpdate
          fetchedAt
        }
        """
        [ Connection.fragment "SpaceUserConnection" SpaceUser.fragment
        , Connection.fragment "GroupConnection" Group.fragment
        ]



-- ACCESSORS


id : Space -> Id
id (Space data) =
    data.id


name : Space -> String
name (Space data) =
    data.name


slug : Space -> String
slug (Space data) =
    data.slug


avatarUrl : Space -> Maybe String
avatarUrl (Space data) =
    data.avatarUrl


avatar : Avatar.Size -> Space -> Html msg
avatar size (Space data) =
    Avatar.thingAvatar size data


openInvitationUrl : Space -> Maybe String
openInvitationUrl (Space data) =
    data.openInvitationUrl


canUpdate : Space -> Bool
canUpdate (Space data) =
    data.canUpdate



-- DECODERS


decoder : Decoder Space
decoder =
    Decode.map Space <|
        (Decode.succeed Data
            |> required "id" Id.decoder
            |> required "name" string
            |> required "slug" string
            |> required "avatarUrl" (maybe string)
            |> required "openInvitationUrl" (maybe string)
            |> custom (Decode.at [ "spaceUsers", "edges" ] (list (Decode.at [ "node", "id" ] Id.decoder)))
            |> custom (Decode.at [ "groups", "edges" ] (list (Decode.at [ "node", "id" ] Id.decoder)))
            |> required "canUpdate" bool
            |> required "fetchedAt" int
        )
