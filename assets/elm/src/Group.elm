module Group exposing (Group, State(..), canManagePermissions, decoder, fragment, id, isBookmarked, isDefault, isPrivate, membershipState, name, setIsBookmarked, setMembershipState, spaceId, state)

import GraphQL exposing (Fragment)
import GroupMembership exposing (GroupMembershipState(..))
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, fail, field, int, string, succeed)
import Json.Decode.Pipeline as Pipeline exposing (custom, required)



-- TYPES


type Group
    = Group Data


type State
    = Open
    | Closed


type alias Data =
    { id : Id
    , spaceId : Id
    , state : State
    , name : String
    , isPrivate : Bool
    , isDefault : Bool
    , isBookmarked : Bool
    , membershipState : GroupMembershipState
    , canManagePermissions : Bool
    , fetchedAt : Int
    }


fragment : Fragment
fragment =
    GraphQL.toFragment
        """
        fragment GroupFields on Group {
          id
          space {
            id
          }
          state
          name
          isPrivate
          isDefault
          isBookmarked
          membership {
            state
          }
          canManagePermissions
          fetchedAt
        }
        """
        []



-- ACCESSORS


id : Group -> Id
id (Group data) =
    data.id


spaceId : Group -> Id
spaceId (Group data) =
    data.spaceId


state : Group -> State
state (Group data) =
    data.state


name : Group -> String
name (Group data) =
    data.name


isPrivate : Group -> Bool
isPrivate (Group data) =
    data.isPrivate


isDefault : Group -> Bool
isDefault (Group data) =
    data.isDefault


isBookmarked : Group -> Bool
isBookmarked (Group data) =
    data.isBookmarked


membershipState : Group -> GroupMembershipState
membershipState (Group data) =
    data.membershipState


canManagePermissions : Group -> Bool
canManagePermissions (Group data) =
    data.canManagePermissions



-- SETTERS


setMembershipState : GroupMembershipState -> Group -> Group
setMembershipState newState (Group data) =
    Group { data | membershipState = newState }


setIsBookmarked : Bool -> Group -> Group
setIsBookmarked val (Group data) =
    Group { data | isBookmarked = val }



-- DECODERS


decoder : Decoder Group
decoder =
    Decode.map Group <|
        (Decode.succeed Data
            |> required "id" Id.decoder
            |> custom (Decode.at [ "space", "id" ] Id.decoder)
            |> required "state" stateDecoder
            |> required "name" string
            |> required "isPrivate" bool
            |> required "isDefault" bool
            |> required "isBookmarked" bool
            |> custom membershipStateDecoder
            |> required "canManagePermissions" bool
            |> required "fetchedAt" int
        )


stateDecoder : Decoder State
stateDecoder =
    let
        convert : String -> Decoder State
        convert raw =
            case raw of
                "OPEN" ->
                    succeed Open

                "CLOSED" ->
                    succeed Closed

                _ ->
                    fail "State not valid"
    in
    Decode.andThen convert string


membershipStateDecoder : Decoder GroupMembershipState
membershipStateDecoder =
    Decode.oneOf
        [ Decode.at [ "membership", "state" ] GroupMembership.stateDecoder
        , Decode.succeed NotSubscribed
        ]
