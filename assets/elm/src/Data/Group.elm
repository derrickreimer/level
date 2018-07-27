module Data.Group exposing (Group, Record, fragment, decoder, getId, getCachedData, setIsBookmarked)

import Data.GroupMembership exposing (GroupMembershipState, stateDecoder)
import Json.Decode as Decode exposing (Decoder, field, string, bool)
import GraphQL exposing (Fragment)


-- TYPES


type Group
    = Group Record


type alias Record =
    { id : String
    , name : String
    , isBookmarked : Bool
    , membershipState : GroupMembershipState
    }


fragment : Fragment
fragment =
    GraphQL.fragment
        """
        fragment GroupFields on Group {
          id
          name
          isBookmarked
          membership {
            state
          }
        }
        """
        []



-- DECODERS


decoder : Decoder Group
decoder =
    Decode.map Group <|
        Decode.map4 Record
            (field "id" string)
            (field "name" string)
            (field "isBookmarked" bool)
            (Decode.at [ "membership", "state" ] stateDecoder)



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
