module GroupMembership exposing (GroupMembership, GroupMembershipState(..), decoder, fragment, stateDecoder, stateEncoder)

import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder, fail, field, string, succeed)
import Json.Encode as Encode
import SpaceUser exposing (SpaceUser)



-- TYPES


type alias GroupMembership =
    { user : SpaceUser
    , state : GroupMembershipState
    , role : GroupRole
    , access : GroupAccess
    }


type GroupMembershipState
    = NotSubscribed
    | Subscribed
    | Watching


type GroupAccess
    = Public
    | Private


type GroupRole
    = Member
    | Owner


fragment : Fragment
fragment =
    GraphQL.toFragment
        """
        fragment GroupMembershipFields on GroupMembership {
          spaceUser {
            ...SpaceUserFields
          }
          state
          role
          access
        }
        """
        [ SpaceUser.fragment
        ]



-- DECODERS


decoder : Decoder GroupMembership
decoder =
    Decode.map4 GroupMembership
        (field "spaceUser" SpaceUser.decoder)
        (field "state" stateDecoder)
        (field "role" roleDecoder)
        (field "access" accessDecoder)


stateDecoder : Decoder GroupMembershipState
stateDecoder =
    let
        convert : String -> Decoder GroupMembershipState
        convert raw =
            case raw of
                "WATCHING" ->
                    succeed Watching

                "SUBSCRIBED" ->
                    succeed Subscribed

                "NOT_SUBSCRIBED" ->
                    succeed NotSubscribed

                _ ->
                    fail "Membership state not valid"
    in
    Decode.andThen convert string


roleDecoder : Decoder GroupRole
roleDecoder =
    let
        convert : String -> Decoder GroupRole
        convert raw =
            case raw of
                "MEMBER" ->
                    succeed Member

                "OWNER" ->
                    succeed Owner

                _ ->
                    fail "Role not valid"
    in
    Decode.andThen convert string


accessDecoder : Decoder GroupAccess
accessDecoder =
    let
        convert : String -> Decoder GroupAccess
        convert raw =
            case raw of
                "PUBLIC" ->
                    succeed Public

                "PRIVATE" ->
                    succeed Private

                _ ->
                    fail "Access not valid"
    in
    Decode.andThen convert string



-- ENCODERS


stateEncoder : GroupMembershipState -> Encode.Value
stateEncoder state =
    case state of
        NotSubscribed ->
            Encode.string "NOT_SUBSCRIBED"

        Subscribed ->
            Encode.string "SUBSCRIBED"

        Watching ->
            Encode.string "WATCHING"
