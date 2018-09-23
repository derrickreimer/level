module Group exposing (Group, Record, decoder, fragment, getCachedData, id, isBookmarked, isPrivate, membershipState, name, setIsBookmarked)

import GraphQL exposing (Fragment)
import GroupMembership exposing (GroupMembershipState(..))
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, field, int, string)



-- TYPES


type Group
    = Group Record


type alias Record =
    { id : Id
    , name : String
    , isPrivate : Bool
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
          name
          isPrivate
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


name : Group -> String
name (Group data) =
    data.name


isPrivate : Group -> Bool
isPrivate (Group data) =
    data.isPrivate


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
        Decode.map6 Record
            (field "id" Id.decoder)
            (field "name" string)
            (field "isPrivate" bool)
            (field "isBookmarked" bool)
            stateDecoder
            (field "fetchedAt" int)


stateDecoder : Decoder GroupMembershipState
stateDecoder =
    Decode.oneOf
        [ Decode.at [ "membership", "state" ] GroupMembership.stateDecoder
        , Decode.succeed NotSubscribed
        ]



-- API


getCachedData : Group -> Record
getCachedData (Group data) =
    data


setIsBookmarked : Bool -> Group -> Group
setIsBookmarked val (Group data) =
    Group { data | isBookmarked = val }
