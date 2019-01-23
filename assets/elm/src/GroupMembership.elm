module GroupMembership exposing (GroupMembership, GroupMembershipState(..), decoder, fragment, stateDecoder, stateEncoder)

import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder, fail, field, string, succeed)
import Json.Encode as Encode
import SpaceUser exposing (SpaceUser)



-- TYPES


type alias GroupMembership =
    { user : SpaceUser
    }


type GroupMembershipState
    = NotSubscribed
    | Subscribed
    | Watching


fragment : Fragment
fragment =
    GraphQL.toFragment
        """
        fragment GroupMembershipFields on GroupMembership {
          spaceUser {
            ...SpaceUserFields
          }
        }
        """
        [ SpaceUser.fragment
        ]



-- DECODERS


decoder : Decoder GroupMembership
decoder =
    Decode.map GroupMembership
        (field "spaceUser" SpaceUser.decoder)


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
