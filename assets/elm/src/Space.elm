module Space exposing (SetupState(..), Space, avatar, avatarUrl, decoder, fragment, id, name, openInvitationUrl, setSetupState, setupRoute, setupStateDecoder, setupStateEncoder, slug)

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
    , setupState : SetupState
    , openInvitationUrl : Maybe String
    , canUpdate : Bool
    , fetchedAt : Int
    }


type SetupState
    = CreateGroups
    | InviteUsers
    | Complete


fragment : Fragment
fragment =
    GraphQL.toFragment
        """
        fragment SpaceFields on Space {
          id
          name
          slug
          avatarUrl
          setupState
          openInvitationUrl
          canUpdate
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



-- DECODERS


decoder : Decoder Space
decoder =
    Decode.map Space <|
        Decode.map8 Data
            (field "id" Id.decoder)
            (field "name" string)
            (field "slug" string)
            (field "avatarUrl" (maybe string))
            (field "setupState" setupStateDecoder)
            (field "openInvitationUrl" (maybe string))
            (field "canUpdate" bool)
            (field "fetchedAt" int)


setupStateDecoder : Decoder SetupState
setupStateDecoder =
    let
        convert : String -> Decoder SetupState
        convert raw =
            case raw of
                "CREATE_GROUPS" ->
                    Decode.succeed CreateGroups

                "INVITE_USERS" ->
                    Decode.succeed InviteUsers

                "COMPLETE" ->
                    Decode.succeed Complete

                _ ->
                    Decode.fail "Setup state not valid"
    in
    Decode.andThen convert string



-- ENCODERS


setupStateEncoder : SetupState -> Encode.Value
setupStateEncoder raw =
    case raw of
        CreateGroups ->
            Encode.string "CREATE_GROUPS"

        InviteUsers ->
            Encode.string "INVITE_USERS"

        Complete ->
            Encode.string "COMPLETE"



-- API


setSetupState : SetupState -> Space -> Space
setSetupState state (Space record) =
    Space { record | setupState = state }



-- ROUTING


setupRoute : String -> SetupState -> Route
setupRoute spaceSlug state =
    case state of
        CreateGroups ->
            Route.SetupCreateGroups spaceSlug

        InviteUsers ->
            Route.SetupInviteUsers spaceSlug

        Complete ->
            Route.Inbox (Route.Inbox.init spaceSlug)
