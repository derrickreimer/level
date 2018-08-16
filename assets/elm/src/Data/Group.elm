module Data.Group exposing (Group, Record, fragment, decoder, getId, getCachedData, setIsBookmarked)

import Data.GroupMembership as GroupMembership exposing (GroupMembershipState(..))
import Json.Decode as Decode exposing (Decoder, field, string, bool, int)
import GraphQL exposing (Fragment)


-- TYPES


type Group
    = Group Record


type alias Record =
    { id : String
    , name : String
    , isPrivate : Bool
    , isBookmarked : Bool
    , membershipState : GroupMembershipState
    , fetchedAt : Int
    }


fragment : Fragment
fragment =
    GraphQL.fragment
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



-- DECODERS


decoder : Decoder Group
decoder =
    Decode.map Group <|
        Decode.map6 Record
            (field "id" string)
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


getId : Group -> String
getId (Group { id }) =
    id


getCachedData : Group -> Record
getCachedData (Group data) =
    data


setIsBookmarked : Bool -> Group -> Group
setIsBookmarked val (Group data) =
    Group { data | isBookmarked = val }
