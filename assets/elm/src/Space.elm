module Space exposing (Space, avatar, avatarUrl, canManageMembers, canUpdate, decoder, fragment, id, name, openInvitationUrl, slug)

import Avatar
import GraphQL exposing (Fragment)
import Html exposing (Html)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, field, int, maybe, string)
import Json.Encode as Encode
import Route exposing (Route)
import Route.Inbox



-- TYPES


type Space
    = Space Data


type alias Data =
    { id : Id
    , name : String
    , slug : String
    , avatarUrl : Maybe String
    , openInvitationUrl : Maybe String
    , canUpdate : Bool
    , canManageMembers : Bool
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
          canUpdate
          canManageMembers
          fetchedAt
        }
        """
        []



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


canManageMembers : Space -> Bool
canManageMembers (Space data) =
    data.canManageMembers



-- DECODERS


decoder : Decoder Space
decoder =
    Decode.map Space <|
        Decode.map8 Data
            (field "id" Id.decoder)
            (field "name" string)
            (field "slug" string)
            (field "avatarUrl" (maybe string))
            (field "openInvitationUrl" (maybe string))
            (field "canUpdate" bool)
            (field "canManageMembers" bool)
            (field "fetchedAt" int)
