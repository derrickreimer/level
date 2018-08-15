module Data.Mention
    exposing
        ( Mention
        , Record
        , fragment
        , decoder
        , getCachedData
        )

import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder, field)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import GraphQL exposing (Fragment)
import Util exposing (dateDecoder)


-- TYPES


type Mention
    = Mention Record


type alias Record =
    { mentioner : SpaceUser
    , occurredAt : Date
    }


fragment : Fragment
fragment =
    GraphQL.fragment
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
        (Decode.map2 Record
            (field "mentioner" SpaceUser.decoder)
            (field "occurredAt" dateDecoder)
        )



-- API


getCachedData : Mention -> Record
getCachedData (Mention data) =
    data
