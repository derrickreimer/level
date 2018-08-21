module Data.Mention exposing (Mention, Record, decoder, fragment, getCachedData)

import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder, field)
import Time exposing (Posix)
import Util exposing (dateDecoder)



-- TYPES


type Mention
    = Mention Record


type alias Record =
    { mentioner : SpaceUser
    , occurredAt : Posix
    }


fragment : Fragment
fragment =
    GraphQL.toFragment
        """
        fragment MentionFields on Mention {
          mentioner {
            ...SpaceUserFields
          }
          occurredAt
        }
        """
        [ SpaceUser.fragment
        ]



-- DECODERS


decoder : Decoder Mention
decoder =
    Decode.map Mention <|
        Decode.map2 Record
            (field "mentioner" SpaceUser.decoder)
            (field "occurredAt" dateDecoder)



-- API


getCachedData : Mention -> Record
getCachedData (Mention data) =
    data
