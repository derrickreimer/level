module Space exposing (Record, SetupState(..), Space, decoder, fragment, getCachedData, getId, getSlug, setSetupState, setupRoute, setupStateDecoder, setupStateEncoder)

import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder, field, int, maybe, string)
import Json.Encode as Encode
import Route exposing (Route)



-- TYPES


type Space
    = Space Record


type alias Record =
    { id : String
    , name : String
    , slug : String
    , avatarUrl : Maybe String
    , setupState : SetupState
    , openInvitationUrl : Maybe String
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
          fetchedAt
        }
        """
        []



-- DECODERS


decoder : Decoder Space
decoder =
    Decode.map Space <|
        Decode.map7 Record
            (field "id" string)
            (field "name" string)
            (field "slug" string)
            (field "avatarUrl" (maybe string))
            (field "setupState" setupStateDecoder)
            (field "openInvitationUrl" (maybe string))
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


getId : Space -> String
getId (Space { id }) =
    id


getSlug : Space -> String
getSlug (Space { slug }) =
    slug


getCachedData : Space -> Record
getCachedData (Space record) =
    record


setSetupState : SetupState -> Space -> Space
setSetupState state (Space record) =
    Space { record | setupState = state }



-- ROUTING


setupRoute : Space -> SetupState -> Route
setupRoute (Space { slug }) state =
    case state of
        CreateGroups ->
            Route.SetupCreateGroups slug

        InviteUsers ->
            Route.SetupInviteUsers slug

        Complete ->
            Route.Inbox slug
