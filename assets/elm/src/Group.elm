module Group exposing (Group, State(..), decoder, fragment, id, isBookmarked, isDefault, isPrivate, membershipState, name, state)

import GraphQL exposing (Fragment)
import GroupMembership exposing (GroupMembershipState(..))
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, fail, field, int, string, succeed)



-- TYPES


type Group
    = Group Data


type State
    = Open
    | Closed


type alias Data =
    { id : Id
    , state : State
    , name : String
    , isPrivate : Bool
    , isDefault : Bool
    , isBookmarked : Bool
    , membershipState : GroupMembershipState
    , fetchedAt : Int
    }


fragment : Fragment
fragment =
    GraphQL.toFragment
        """
        fragment GroupFields on Group {
          id
          state
          name
          isPrivate
          isDefault
          isBookmarked
          membership {
            state
          }
          fetchedAt
        }
        """
        []



-- ACCESSORS


id : Group -> Id
id (Group data) =
    data.id


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



-- DECODERS


decoder : Decoder Group
decoder =
    Decode.map Group <|
        Decode.map8 Data
            (field "id" Id.decoder)
            (field "state" stateDecoder)
            (field "name" string)
            (field "isPrivate" bool)
            (field "isDefault" bool)
            (field "isBookmarked" bool)
            membershipStateDecoder
            (field "fetchedAt" int)


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
